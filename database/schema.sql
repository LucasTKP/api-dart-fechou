-- Schema idempotente do Kanban
-- Tabelas e tipos em public; helpers internos em private; funções RPC em public.
-- Pode executar várias vezes: cria o que não existe e atualiza o que já existe.
-- Para aplicar schema + funções + triggers de uma vez: ./database/aplicar.sh

-- ---------------------------------------------------------------------------
-- schema private (apenas helpers internos)
-- ---------------------------------------------------------------------------
create schema if not exists private;

revoke all on schema private from public;
revoke all on schema private from anon;
revoke all on schema private from authenticated;

grant usage on schema private to postgres;
grant usage on schema private to service_role;

-- ---------------------------------------------------------------------------
-- migração: private → public
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('public.cards') is not null
     and to_regclass('public.cartoes') is null then
    alter table public.cards rename to cartoes;
  end if;
end
$$;

do $$
declare
  v_tipo record;
begin
  for v_tipo in
    select t.typname
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'private'
      and t.typtype = 'e'
      and to_regtype('public.' || t.typname) is null
  loop
    execute format('alter type private.%I set schema public', v_tipo.typname);
  end loop;
end
$$;

do $$
declare
  v_tabela text;
begin
  foreach v_tabela in array array[
    'usuarios',
    'organizacoes',
    'membros_organizacao',
    'convites_organizacao',
    'clientes',
    'quadros',
    'colunas_quadros',
    'cartoes',
    'agendamentos',
    'regras_captacao_automatica'
  ]
  loop
    if to_regclass('private.' || v_tabela) is not null
       and to_regclass('public.' || v_tabela) is null then
      execute format('alter table private.%I set schema public', v_tabela);
    end if;
  end loop;
end
$$;

-- ---------------------------------------------------------------------------
-- enum de cores
-- ---------------------------------------------------------------------------
do $$
begin
  create type public.cor_kanban as enum (
    'azul', 'verde', 'vermelho', 'amarelo', 'roxo', 'laranja', 'rosa', 'cinza'
  );
exception
  when duplicate_object then null;
end
$$;

-- ---------------------------------------------------------------------------
-- enums de agendamentos
-- ---------------------------------------------------------------------------
do $$
begin
  create type public.tipo_agendamento as enum (
    'reuniao', 'ligacao', 'visita'
  );
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.status_agendamento as enum (
    'pendente', 'concluido', 'cancelado'
  );
exception
  when duplicate_object then null;
end
$$;

-- ---------------------------------------------------------------------------
-- enum de origem do cartão
-- ---------------------------------------------------------------------------
do $$
begin
  create type public.origem_cartao as enum (
    'whatsapp', 'instagram', 'trafego_pago', 'indicacao'
  );
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  if exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typname = 'origem_cliente'
  ) and not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typname = 'origem_cartao'
  ) then
    alter type public.origem_cliente rename to origem_cartao;
  end if;
exception
  when duplicate_object then null;
end
$$;

-- ---------------------------------------------------------------------------
-- usuarios
-- ---------------------------------------------------------------------------
create table if not exists public.usuarios (
    id uuid primary key,
    nome text not null,
    email text not null unique,
    criado_em timestamptz not null default now()
);

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'usuarios' and column_name = 'created_at'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'usuarios' and column_name = 'criado_em'
  ) then
    alter table public.usuarios rename column created_at to criado_em;
  end if;

  alter table public.usuarios alter column id drop default;
exception
  when others then null;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'usuarios_id_fkey' and conrelid = 'public.usuarios'::regclass
  ) and not exists (
    select 1
    from pg_constraint c
    join pg_attribute a on a.attrelid = c.conrelid and a.attnum = any (c.conkey)
    where c.conrelid = 'public.usuarios'::regclass
      and c.contype = 'f'
      and a.attname = 'id'
  ) then
    alter table public.usuarios
      add constraint usuarios_id_fkey
      foreign key (id) references auth.users (id) on update cascade on delete cascade;
  end if;
end
$$;

create index if not exists indice_usuarios_email on public.usuarios (email);

comment on table public.usuarios is 'Usuários do sistema Kanban';

-- ---------------------------------------------------------------------------
-- enums de organizações
-- ---------------------------------------------------------------------------
do $$
begin
  create type public.papel_membro_organizacao as enum (
    'proprietario', 'admin', 'membro'
  );
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.status_convite_organizacao as enum (
    'pendente', 'aceito', 'recusado', 'expirado'
  );
exception
  when duplicate_object then null;
end
$$;

-- ---------------------------------------------------------------------------
-- organizacoes
-- ---------------------------------------------------------------------------
create table if not exists public.organizacoes (
    id uuid primary key default gen_random_uuid (),
    nome text not null,
    criado_por uuid not null,
    criado_em timestamptz not null default now(),
    ativa boolean not null default false
);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'organizacoes_criado_por_fkey'
      and conrelid = 'public.organizacoes'::regclass
  ) then
    alter table public.organizacoes
      add constraint organizacoes_criado_por_fkey
      foreign key (criado_por) references public.usuarios (id) on update cascade on delete restrict;
  end if;
end
$$;

create index if not exists indice_organizacoes_criado_por
  on public.organizacoes (criado_por);

alter table public.organizacoes add column if not exists ativa boolean;

update public.organizacoes
set ativa = true
where ativa is null;

alter table public.organizacoes
  alter column ativa set default false;

alter table public.organizacoes
  alter column ativa set not null;

comment on table public.organizacoes is 'Organizações (tenants) do sistema';

comment on column public.organizacoes.ativa is
  'Indica se a organização está ativa (assinatura paga). Novas organizações começam inativas.';

-- ---------------------------------------------------------------------------
-- membros_organizacao
-- ---------------------------------------------------------------------------
create table if not exists public.membros_organizacao (
    id uuid primary key default gen_random_uuid (),
    organizacao_id uuid not null,
    usuario_id uuid not null,
    papel public.papel_membro_organizacao not null default 'membro',
    entrado_em timestamptz not null default now(),
    unique (organizacao_id, usuario_id)
);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'membros_organizacao_organizacao_id_fkey'
      and conrelid = 'public.membros_organizacao'::regclass
  ) then
    alter table public.membros_organizacao
      add constraint membros_organizacao_organizacao_id_fkey
      foreign key (organizacao_id) references public.organizacoes (id) on update cascade on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'membros_organizacao_usuario_id_fkey'
      and conrelid = 'public.membros_organizacao'::regclass
  ) then
    alter table public.membros_organizacao
      add constraint membros_organizacao_usuario_id_fkey
      foreign key (usuario_id) references public.usuarios (id) on update cascade on delete cascade;
  end if;
end
$$;

create index if not exists indice_membros_organizacao_organizacao_id
  on public.membros_organizacao (organizacao_id);

create index if not exists indice_membros_organizacao_usuario_id
  on public.membros_organizacao (usuario_id);

comment on table public.membros_organizacao is
  'Vínculo entre usuários e organizações, com papel de acesso';

-- ---------------------------------------------------------------------------
-- convites_organizacao (preparado para convites futuros)
-- ---------------------------------------------------------------------------
create table if not exists public.convites_organizacao (
    id uuid primary key default gen_random_uuid (),
    organizacao_id uuid not null,
    email text not null,
    papel public.papel_membro_organizacao not null default 'membro',
    convidado_por uuid not null,
    token text not null unique default gen_random_uuid()::text,
    status public.status_convite_organizacao not null default 'pendente',
    expira_em timestamptz not null default (now() + interval '7 days'),
    criado_em timestamptz not null default now(),
    respondido_em timestamptz
);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'convites_organizacao_organizacao_id_fkey'
      and conrelid = 'public.convites_organizacao'::regclass
  ) then
    alter table public.convites_organizacao
      add constraint convites_organizacao_organizacao_id_fkey
      foreign key (organizacao_id) references public.organizacoes (id) on update cascade on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'convites_organizacao_convidado_por_fkey'
      and conrelid = 'public.convites_organizacao'::regclass
  ) then
    alter table public.convites_organizacao
      add constraint convites_organizacao_convidado_por_fkey
      foreign key (convidado_por) references public.usuarios (id) on update cascade on delete cascade;
  end if;
end
$$;

create index if not exists indice_convites_organizacao_organizacao_id
  on public.convites_organizacao (organizacao_id);

create index if not exists indice_convites_organizacao_email
  on public.convites_organizacao (email);

create unique index if not exists indice_convites_organizacao_pendente_unico
  on public.convites_organizacao (organizacao_id, email)
  where status = 'pendente';

comment on table public.convites_organizacao is
  'Convites pendentes para ingressar em uma organização (uso futuro)';

-- ---------------------------------------------------------------------------
-- clientes
-- ---------------------------------------------------------------------------
create table if not exists public.clientes (
    id uuid primary key default gen_random_uuid (),
    organizacao_id uuid not null,
    criado_por uuid not null,
    nome text not null,
    email text,
    telefone text,
    empresa text,
    criado_em timestamptz not null default now()
);

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'clientes' and column_name = 'created_at'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'clientes' and column_name = 'criado_em'
  ) then
    alter table public.clientes rename column created_at to criado_em;
  end if;

  alter table public.clientes add column if not exists criado_por uuid;
  alter table public.clientes add column if not exists organizacao_id uuid;
  alter table public.clientes drop column if exists origem;

  if not exists (
    select 1 from pg_constraint
    where conname = 'clientes_organizacao_id_fkey'
      and conrelid = 'public.clientes'::regclass
  ) then
    alter table public.clientes
      add constraint clientes_organizacao_id_fkey
      foreign key (organizacao_id) references public.organizacoes (id) on update cascade on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'clientes_criado_por_fkey' and conrelid = 'public.clientes'::regclass
  ) and not exists (
    select 1
    from pg_constraint c
    join pg_attribute a on a.attrelid = c.conrelid and a.attnum = any (c.conkey)
    where c.conrelid = 'public.clientes'::regclass
      and c.contype = 'f'
      and a.attname = 'criado_por'
  ) then
    alter table public.clientes
      add constraint clientes_criado_por_fkey
      foreign key (criado_por) references public.usuarios (id) on update cascade on delete cascade;
  end if;
end
$$;

create index if not exists indice_clientes_organizacao_id
  on public.clientes (organizacao_id);

create index if not exists indice_clientes_criado_por on public.clientes (criado_por);

create index if not exists indice_clientes_nome on public.clientes (nome);

comment on
table public.clientes is 'Clientes vinculados aos cartões do Kanban';

-- ---------------------------------------------------------------------------
-- quadros
-- ---------------------------------------------------------------------------
create table if not exists public.quadros (
    id uuid primary key default gen_random_uuid (),
    organizacao_id uuid not null,
    criado_por uuid not null,
    nome text not null,
    descricao text,
    cor public.cor_kanban not null default 'roxo',
    ordem integer not null default 0,
    criado_em timestamptz not null default now()
);

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'quadros' and column_name = 'created_at'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'quadros' and column_name = 'criado_em'
  ) then
    alter table public.quadros rename column created_at to criado_em;
  end if;

  alter table public.quadros add column if not exists descricao text;
  alter table public.quadros add column if not exists cor public.cor_kanban not null default 'roxo';
  alter table public.quadros add column if not exists ordem integer not null default 0;
  alter table public.quadros add column if not exists organizacao_id uuid;

  if not exists (
    select 1 from pg_constraint
    where conname = 'quadros_organizacao_id_fkey'
      and conrelid = 'public.quadros'::regclass
  ) then
    alter table public.quadros
      add constraint quadros_organizacao_id_fkey
      foreign key (organizacao_id) references public.organizacoes (id) on update cascade on delete cascade;
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'quadros'
      and column_name = 'cor' and udt_name = 'text'
  ) then
    alter table public.quadros
      alter column cor type public.cor_kanban
      using (
        case lower(cor)
          when '#6366f1' then 'roxo'::public.cor_kanban
          when '#94a3b8' then 'cinza'::public.cor_kanban
          when 'azul' then 'azul'::public.cor_kanban
          when 'verde' then 'verde'::public.cor_kanban
          when 'vermelho' then 'vermelho'::public.cor_kanban
          when 'amarelo' then 'amarelo'::public.cor_kanban
          when 'roxo' then 'roxo'::public.cor_kanban
          when 'laranja' then 'laranja'::public.cor_kanban
          when 'rosa' then 'rosa'::public.cor_kanban
          when 'cinza' then 'cinza'::public.cor_kanban
          else 'roxo'::public.cor_kanban
        end
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'quadros_criado_por_fkey' and conrelid = 'public.quadros'::regclass
  ) and not exists (
    select 1
    from pg_constraint c
    join pg_attribute a on a.attrelid = c.conrelid and a.attnum = any (c.conkey)
    where c.conrelid = 'public.quadros'::regclass
      and c.contype = 'f'
      and a.attname = 'criado_por'
  ) then
    alter table public.quadros
      add constraint quadros_criado_por_fkey
      foreign key (criado_por) references public.usuarios (id) on update cascade on delete cascade;
  end if;
end
$$;

create index if not exists indice_quadros_organizacao_id
  on public.quadros (organizacao_id);

create index if not exists indice_quadros_criado_por on public.quadros (criado_por);

create index if not exists indice_quadros_ordem on public.quadros (organizacao_id, ordem);

comment on table public.quadros is 'Quadros do Kanban';

-- ---------------------------------------------------------------------------
-- colunas_quadros
-- ---------------------------------------------------------------------------
create table if not exists public.colunas_quadros (
    id uuid primary key default gen_random_uuid (),
    quadro_id uuid not null,
    nome text not null,
    cor public.cor_kanban not null default 'cinza',
    ordem integer not null default 0,
    criado_em timestamptz not null default now()
);

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'colunas_quadros' and column_name = 'created_at'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'colunas_quadros' and column_name = 'criado_em'
  ) then
    alter table public.colunas_quadros rename column created_at to criado_em;
  end if;

  alter table public.colunas_quadros add column if not exists cor public.cor_kanban not null default 'cinza';
  alter table public.colunas_quadros add column if not exists ordem integer not null default 0;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'colunas_quadros'
      and column_name = 'cor' and udt_name = 'text'
  ) then
    alter table public.colunas_quadros
      alter column cor type public.cor_kanban
      using (
        case lower(cor)
          when '#6366f1' then 'roxo'::public.cor_kanban
          when '#94a3b8' then 'cinza'::public.cor_kanban
          when 'azul' then 'azul'::public.cor_kanban
          when 'verde' then 'verde'::public.cor_kanban
          when 'vermelho' then 'vermelho'::public.cor_kanban
          when 'amarelo' then 'amarelo'::public.cor_kanban
          when 'roxo' then 'roxo'::public.cor_kanban
          when 'laranja' then 'laranja'::public.cor_kanban
          when 'rosa' then 'rosa'::public.cor_kanban
          when 'cinza' then 'cinza'::public.cor_kanban
          else 'cinza'::public.cor_kanban
        end
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'colunas_quadros_quadro_id_fkey'
      and conrelid = 'public.colunas_quadros'::regclass
  ) and not exists (
    select 1
    from pg_constraint c
    join pg_attribute a on a.attrelid = c.conrelid and a.attnum = any (c.conkey)
    where c.conrelid = 'public.colunas_quadros'::regclass
      and c.contype = 'f'
      and a.attname = 'quadro_id'
  ) then
    alter table public.colunas_quadros
      add constraint colunas_quadros_quadro_id_fkey
      foreign key (quadro_id) references public.quadros (id) on update cascade on delete cascade;
  end if;
end
$$;

create index if not exists indice_colunas_quadros_quadro_id on public.colunas_quadros (quadro_id);

create index if not exists indice_colunas_quadros_ordem on public.colunas_quadros (quadro_id, ordem);

comment on
table public.colunas_quadros is 'Colunas de cada quadro Kanban';

-- ---------------------------------------------------------------------------
-- cartoes
-- ---------------------------------------------------------------------------
create table if not exists public.cartoes (
    id uuid primary key default gen_random_uuid (),
    cliente_id uuid,
    quadro_id uuid not null,
    coluna_id uuid not null,
    responsavel_id uuid,
    titulo text not null,
    observacao text,
    ordem integer not null default 0,
    valor_proposta integer,
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now()
);

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'cartoes' and column_name = 'created_at'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'cartoes' and column_name = 'criado_em'
  ) then
    alter table public.cartoes rename column created_at to criado_em;
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'cartoes' and column_name = 'updated_at'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'cartoes' and column_name = 'atualizado_em'
  ) then
    alter table public.cartoes rename column updated_at to atualizado_em;
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'cartoes' and column_name = 'descricao'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'cartoes' and column_name = 'observacao'
  ) then
    alter table public.cartoes rename column descricao to observacao;
  end if;

  alter table public.cartoes add column if not exists observacao text;
  alter table public.cartoes add column if not exists ordem integer not null default 0;
  alter table public.cartoes drop column if exists data_limite;
  alter table public.cartoes drop column if exists data_proxima_reuniao;
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'cartoes' and column_name = 'valor_proposta'
  ) then
    alter table public.cartoes add column valor_proposta integer;
  elsif exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'cartoes'
      and column_name = 'valor_proposta'
      and data_type = 'numeric'
  ) then
    alter table public.cartoes
      alter column valor_proposta type integer
      using (round(valor_proposta * 100)::integer);
  end if;
  alter table public.cartoes add column if not exists atualizado_em timestamptz not null default now();
  alter table public.cartoes add column if not exists origem public.origem_cartao;

  if exists (
    select 1 from pg_constraint
    where conname = 'cartoes_cliente_id_fkey' and conrelid = 'public.cartoes'::regclass
  ) then
    alter table public.cartoes drop constraint cartoes_cliente_id_fkey;
  end if;

  if not exists (
    select 1
    from pg_constraint c
    join pg_attribute a on a.attrelid = c.conrelid and a.attnum = any (c.conkey)
    where c.conrelid = 'public.cartoes'::regclass
      and c.contype = 'f'
      and a.attname = 'cliente_id'
  ) then
    alter table public.cartoes
      add constraint cartoes_cliente_id_fkey
      foreign key (cliente_id) references public.clientes (id) on update cascade on delete set null;
  end if;

  alter table public.cartoes alter column cliente_id drop not null;

  if not exists (
    select 1 from pg_constraint
    where conname = 'cartoes_quadro_id_fkey' and conrelid = 'public.cartoes'::regclass
  ) and not exists (
    select 1
    from pg_constraint c
    join pg_attribute a on a.attrelid = c.conrelid and a.attnum = any (c.conkey)
    where c.conrelid = 'public.cartoes'::regclass
      and c.contype = 'f'
      and a.attname = 'quadro_id'
  ) then
    alter table public.cartoes
      add constraint cartoes_quadro_id_fkey
      foreign key (quadro_id) references public.quadros (id) on update cascade on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'cartoes_coluna_id_fkey' and conrelid = 'public.cartoes'::regclass
  ) and not exists (
    select 1
    from pg_constraint c
    join pg_attribute a on a.attrelid = c.conrelid and a.attnum = any (c.conkey)
    where c.conrelid = 'public.cartoes'::regclass
      and c.contype = 'f'
      and a.attname = 'coluna_id'
  ) then
    alter table public.cartoes
      add constraint cartoes_coluna_id_fkey
      foreign key (coluna_id) references public.colunas_quadros (id) on update cascade on delete restrict;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'cartoes_responsavel_id_fkey' and conrelid = 'public.cartoes'::regclass
  ) and not exists (
    select 1
    from pg_constraint c
    join pg_attribute a on a.attrelid = c.conrelid and a.attnum = any (c.conkey)
    where c.conrelid = 'public.cartoes'::regclass
      and c.contype = 'f'
      and a.attname = 'responsavel_id'
  ) then
    alter table public.cartoes
      add constraint cartoes_responsavel_id_fkey
      foreign key (responsavel_id) references public.usuarios (id) on update cascade on delete set null;
  end if;
end
$$;

create index if not exists indice_cartoes_quadro_id on public.cartoes (quadro_id);

create index if not exists indice_cartoes_coluna_id on public.cartoes (coluna_id);

create index if not exists indice_cartoes_cliente_id on public.cartoes (cliente_id);

create index if not exists indice_cartoes_responsavel_id on public.cartoes (responsavel_id);

create index if not exists indice_cartoes_ordem on public.cartoes (coluna_id, ordem);

comment on table public.cartoes is 'Cartões do Kanban';

-- ---------------------------------------------------------------------------
-- agendamentos
-- ---------------------------------------------------------------------------
create table if not exists public.agendamentos (
    id uuid primary key default gen_random_uuid (),
    organizacao_id uuid not null,
    criado_por uuid not null,
    responsavel_id uuid,
    cliente_id uuid,
    cartao_id uuid,
    titulo text not null,
    descricao text,
    tipo public.tipo_agendamento not null,
    status public.status_agendamento not null default 'pendente',
    data_hora_inicio timestamptz not null,
    data_hora_fim timestamptz,
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now()
);

do $$
begin
  alter table public.agendamentos add column if not exists organizacao_id uuid;
  alter table public.agendamentos alter column responsavel_id drop not null;

  if not exists (
    select 1 from pg_constraint
    where conname = 'agendamentos_organizacao_id_fkey'
      and conrelid = 'public.agendamentos'::regclass
  ) then
    alter table public.agendamentos
      add constraint agendamentos_organizacao_id_fkey
      foreign key (organizacao_id) references public.organizacoes (id) on update cascade on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'agendamentos_criado_por_fkey' and conrelid = 'public.agendamentos'::regclass
  ) then
    alter table public.agendamentos
      add constraint agendamentos_criado_por_fkey
      foreign key (criado_por) references public.usuarios (id) on update cascade on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'agendamentos_responsavel_id_fkey' and conrelid = 'public.agendamentos'::regclass
  ) then
    alter table public.agendamentos
      add constraint agendamentos_responsavel_id_fkey
      foreign key (responsavel_id) references public.usuarios (id) on update cascade on delete set null;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'agendamentos_cliente_id_fkey' and conrelid = 'public.agendamentos'::regclass
  ) then
    alter table public.agendamentos
      add constraint agendamentos_cliente_id_fkey
      foreign key (cliente_id) references public.clientes (id) on update cascade on delete set null;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'agendamentos_cartao_id_fkey' and conrelid = 'public.agendamentos'::regclass
  ) then
    alter table public.agendamentos
      add constraint agendamentos_cartao_id_fkey
      foreign key (cartao_id) references public.cartoes (id) on update cascade on delete set null;
  end if;
end
$$;

create index if not exists indice_agendamentos_organizacao_id
  on public.agendamentos (organizacao_id);

create index if not exists indice_agendamentos_criado_por on public.agendamentos (criado_por);

create index if not exists indice_agendamentos_responsavel_id on public.agendamentos (responsavel_id);

create index if not exists indice_agendamentos_cliente_id on public.agendamentos (cliente_id);

create index if not exists indice_agendamentos_cartao_id on public.agendamentos (cartao_id);

create index if not exists indice_agendamentos_status on public.agendamentos (status);

create index if not exists indice_agendamentos_data_hora_inicio on public.agendamentos (data_hora_inicio);

create index if not exists indice_agendamentos_responsavel_data
  on public.agendamentos (responsavel_id, data_hora_inicio);

comment on table public.agendamentos is 'Agendamentos de reuniões, ligações e visitas';

-- ---------------------------------------------------------------------------
-- helper: normalização de texto para captação automática
-- ---------------------------------------------------------------------------
create or replace function private.normalizar_texto_mensagem(p_texto text)
returns text
language sql
immutable
parallel safe
set search_path = ''
as $$
  select lower(trim(regexp_replace(coalesce(p_texto, ''), '\s+', ' ', 'g')));
$$;

comment on function private.normalizar_texto_mensagem(text) is
  'Normaliza texto para comparação de palavra-chave (minúsculas, trim, espaços colapsados).';

create or replace function private.normalizar_telefone_br(p_telefone text)
returns text
language sql
immutable
parallel safe
set search_path = ''
as $$
  select case
    when t.digitos = '' then ''
    when left(t.digitos, 2) = '55' and length(t.digitos) in (12, 13)
      then substring(t.digitos from 3)
    else t.digitos
  end
  from (
    select regexp_replace(coalesce(p_telefone, ''), '\D', '', 'g') as digitos
  ) t;
$$;

comment on function private.normalizar_telefone_br(text) is
  'Normaliza telefone BR: remove máscara e +55, mantendo DDD + número.';

-- ---------------------------------------------------------------------------
-- regras_captacao_automatica
-- ---------------------------------------------------------------------------
create table if not exists public.regras_captacao_automatica (
    id uuid primary key default gen_random_uuid (),
    organizacao_id uuid not null,
    criado_por uuid not null,
    nome text not null,
    palavra_chave text not null,
    quadro_id uuid not null,
    coluna_id uuid not null,
    origem public.origem_cartao not null,
    ativo boolean not null default true,
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now()
);

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'regras_captacao_automatica'
      and column_name = 'titulo_cartao'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'regras_captacao_automatica'
      and column_name = 'origem'
  ) then
    alter table public.regras_captacao_automatica
      rename column titulo_cartao to origem;
  end if;

  alter table public.regras_captacao_automatica
    add column if not exists palavra_chave_normalizada text
    generated always as (private.normalizar_texto_mensagem(palavra_chave)) stored;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'regras_captacao_automatica'
      and column_name = 'origem'
      and udt_name = 'text'
  ) then
    alter table public.regras_captacao_automatica
      alter column origem type public.origem_cartao
      using case
        when lower(trim(origem)) in (
          'whatsapp', 'instagram', 'trafego_pago', 'indicacao'
        ) then lower(trim(origem))::public.origem_cartao
        else 'whatsapp'::public.origem_cartao
      end;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'regras_captacao_automatica_organizacao_id_fkey'
      and conrelid = 'public.regras_captacao_automatica'::regclass
  ) then
    alter table public.regras_captacao_automatica
      add constraint regras_captacao_automatica_organizacao_id_fkey
      foreign key (organizacao_id) references public.organizacoes (id) on update cascade on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'regras_captacao_automatica_criado_por_fkey'
      and conrelid = 'public.regras_captacao_automatica'::regclass
  ) then
    alter table public.regras_captacao_automatica
      add constraint regras_captacao_automatica_criado_por_fkey
      foreign key (criado_por) references public.usuarios (id) on update cascade on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'regras_captacao_automatica_quadro_id_fkey'
      and conrelid = 'public.regras_captacao_automatica'::regclass
  ) then
    alter table public.regras_captacao_automatica
      add constraint regras_captacao_automatica_quadro_id_fkey
      foreign key (quadro_id) references public.quadros (id) on update cascade on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'regras_captacao_automatica_coluna_id_fkey'
      and conrelid = 'public.regras_captacao_automatica'::regclass
  ) then
    alter table public.regras_captacao_automatica
      add constraint regras_captacao_automatica_coluna_id_fkey
      foreign key (coluna_id) references public.colunas_quadros (id) on update cascade on delete restrict;
  end if;
end
$$;

create index if not exists indice_regras_captacao_automatica_organizacao_id
  on public.regras_captacao_automatica (organizacao_id);

create index if not exists indice_regras_captacao_automatica_ativas
  on public.regras_captacao_automatica (organizacao_id, criado_em)
  where ativo = true;

create index if not exists indice_cartoes_origem
  on public.cartoes (quadro_id, origem)
  where origem is not null;

comment on table public.regras_captacao_automatica is
  'Regras de captação automática de leads via WhatsApp por palavra-chave.';

comment on column public.regras_captacao_automatica.palavra_chave_normalizada is
  'Versão normalizada de palavra_chave, pré-calculada para busca rápida em cada mensagem.';

-- ---------------------------------------------------------------------------
-- migração: ON UPDATE CASCADE em todas as FKs
-- ---------------------------------------------------------------------------
do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'usuarios_id_fkey'
      and conrelid = 'public.usuarios'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.usuarios drop constraint usuarios_id_fkey;
    alter table public.usuarios
      add constraint usuarios_id_fkey
      foreign key (id) references auth.users (id) on update cascade on delete cascade;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'organizacoes_criado_por_fkey'
      and conrelid = 'public.organizacoes'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.organizacoes drop constraint organizacoes_criado_por_fkey;
    alter table public.organizacoes
      add constraint organizacoes_criado_por_fkey
      foreign key (criado_por) references public.usuarios (id) on update cascade on delete restrict;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'membros_organizacao_organizacao_id_fkey'
      and conrelid = 'public.membros_organizacao'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.membros_organizacao drop constraint membros_organizacao_organizacao_id_fkey;
    alter table public.membros_organizacao
      add constraint membros_organizacao_organizacao_id_fkey
      foreign key (organizacao_id) references public.organizacoes (id) on update cascade on delete cascade;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'membros_organizacao_usuario_id_fkey'
      and conrelid = 'public.membros_organizacao'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.membros_organizacao drop constraint membros_organizacao_usuario_id_fkey;
    alter table public.membros_organizacao
      add constraint membros_organizacao_usuario_id_fkey
      foreign key (usuario_id) references public.usuarios (id) on update cascade on delete cascade;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'convites_organizacao_organizacao_id_fkey'
      and conrelid = 'public.convites_organizacao'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.convites_organizacao drop constraint convites_organizacao_organizacao_id_fkey;
    alter table public.convites_organizacao
      add constraint convites_organizacao_organizacao_id_fkey
      foreign key (organizacao_id) references public.organizacoes (id) on update cascade on delete cascade;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'convites_organizacao_convidado_por_fkey'
      and conrelid = 'public.convites_organizacao'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.convites_organizacao drop constraint convites_organizacao_convidado_por_fkey;
    alter table public.convites_organizacao
      add constraint convites_organizacao_convidado_por_fkey
      foreign key (convidado_por) references public.usuarios (id) on update cascade on delete cascade;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'clientes_organizacao_id_fkey'
      and conrelid = 'public.clientes'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.clientes drop constraint clientes_organizacao_id_fkey;
    alter table public.clientes
      add constraint clientes_organizacao_id_fkey
      foreign key (organizacao_id) references public.organizacoes (id) on update cascade on delete cascade;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'clientes_criado_por_fkey'
      and conrelid = 'public.clientes'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.clientes drop constraint clientes_criado_por_fkey;
    alter table public.clientes
      add constraint clientes_criado_por_fkey
      foreign key (criado_por) references public.usuarios (id) on update cascade on delete cascade;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'quadros_organizacao_id_fkey'
      and conrelid = 'public.quadros'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.quadros drop constraint quadros_organizacao_id_fkey;
    alter table public.quadros
      add constraint quadros_organizacao_id_fkey
      foreign key (organizacao_id) references public.organizacoes (id) on update cascade on delete cascade;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'quadros_criado_por_fkey'
      and conrelid = 'public.quadros'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.quadros drop constraint quadros_criado_por_fkey;
    alter table public.quadros
      add constraint quadros_criado_por_fkey
      foreign key (criado_por) references public.usuarios (id) on update cascade on delete cascade;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'colunas_quadros_quadro_id_fkey'
      and conrelid = 'public.colunas_quadros'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.colunas_quadros drop constraint colunas_quadros_quadro_id_fkey;
    alter table public.colunas_quadros
      add constraint colunas_quadros_quadro_id_fkey
      foreign key (quadro_id) references public.quadros (id) on update cascade on delete cascade;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'cartoes_cliente_id_fkey'
      and conrelid = 'public.cartoes'::regclass
      and confdeltype <> 'n'
  ) then
    alter table public.cartoes drop constraint cartoes_cliente_id_fkey;
    alter table public.cartoes
      add constraint cartoes_cliente_id_fkey
      foreign key (cliente_id) references public.clientes (id) on update cascade on delete set null;
  end if;

  alter table public.cartoes alter column cliente_id drop not null;

  if exists (
    select 1 from pg_constraint
    where conname = 'cartoes_quadro_id_fkey'
      and conrelid = 'public.cartoes'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.cartoes drop constraint cartoes_quadro_id_fkey;
    alter table public.cartoes
      add constraint cartoes_quadro_id_fkey
      foreign key (quadro_id) references public.quadros (id) on update cascade on delete cascade;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'cartoes_coluna_id_fkey'
      and conrelid = 'public.cartoes'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.cartoes drop constraint cartoes_coluna_id_fkey;
    alter table public.cartoes
      add constraint cartoes_coluna_id_fkey
      foreign key (coluna_id) references public.colunas_quadros (id) on update cascade on delete restrict;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'cartoes_responsavel_id_fkey'
      and conrelid = 'public.cartoes'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.cartoes drop constraint cartoes_responsavel_id_fkey;
    alter table public.cartoes
      add constraint cartoes_responsavel_id_fkey
      foreign key (responsavel_id) references public.usuarios (id) on update cascade on delete set null;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'agendamentos_organizacao_id_fkey'
      and conrelid = 'public.agendamentos'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.agendamentos drop constraint agendamentos_organizacao_id_fkey;
    alter table public.agendamentos
      add constraint agendamentos_organizacao_id_fkey
      foreign key (organizacao_id) references public.organizacoes (id) on update cascade on delete cascade;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'agendamentos_criado_por_fkey'
      and conrelid = 'public.agendamentos'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.agendamentos drop constraint agendamentos_criado_por_fkey;
    alter table public.agendamentos
      add constraint agendamentos_criado_por_fkey
      foreign key (criado_por) references public.usuarios (id) on update cascade on delete cascade;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'agendamentos_responsavel_id_fkey'
      and conrelid = 'public.agendamentos'::regclass
      and (confupdtype <> 'c' or confdeltype <> 'n')
  ) then
    alter table public.agendamentos drop constraint agendamentos_responsavel_id_fkey;
    alter table public.agendamentos alter column responsavel_id drop not null;
    alter table public.agendamentos
      add constraint agendamentos_responsavel_id_fkey
      foreign key (responsavel_id) references public.usuarios (id) on update cascade on delete set null;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'agendamentos_cliente_id_fkey'
      and conrelid = 'public.agendamentos'::regclass
      and confdeltype <> 'n'
  ) then
    alter table public.agendamentos drop constraint agendamentos_cliente_id_fkey;
    alter table public.agendamentos
      add constraint agendamentos_cliente_id_fkey
      foreign key (cliente_id) references public.clientes (id) on update cascade on delete set null;
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'agendamentos_cartao_id_fkey'
      and conrelid = 'public.agendamentos'::regclass
      and confupdtype <> 'c'
  ) then
    alter table public.agendamentos drop constraint agendamentos_cartao_id_fkey;
    alter table public.agendamentos
      add constraint agendamentos_cartao_id_fkey
      foreign key (cartao_id) references public.cartoes (id) on update cascade on delete set null;
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- migração: organização padrão e vínculo de dados existentes
-- ---------------------------------------------------------------------------
do $$
declare
  v_usuario_legado uuid;
begin
  select u.id
  into v_usuario_legado
  from public.usuarios u
  order by u.criado_em
  limit 1;

  if v_usuario_legado is not null then
    update public.clientes
    set criado_por = v_usuario_legado
    where criado_por is null;

    update public.quadros
    set criado_por = v_usuario_legado
    where criado_por is null;

    update public.agendamentos
    set criado_por = v_usuario_legado
    where criado_por is null;
  end if;

  insert into public.organizacoes (nome, criado_por)
  select
    case
      when nullif(trim(u.nome), '') is not null
        then 'Organização de ' || trim(u.nome)
      else 'Minha organização'
    end,
    u.id
  from public.usuarios u
  where not exists (
    select 1
    from public.membros_organizacao m
    where m.usuario_id = u.id
  );

  insert into public.membros_organizacao (organizacao_id, usuario_id, papel)
  select o.id, o.criado_por, 'proprietario'::public.papel_membro_organizacao
  from public.organizacoes o
  where not exists (
    select 1
    from public.membros_organizacao m
    where m.organizacao_id = o.id
      and m.usuario_id = o.criado_por
  );

  update public.clientes c
  set organizacao_id = sub.organizacao_id
  from (
    select
      m.usuario_id,
      min(m.organizacao_id::text)::uuid as organizacao_id
    from public.membros_organizacao m
    group by m.usuario_id
  ) sub
  where c.organizacao_id is null
    and c.criado_por = sub.usuario_id;

  update public.quadros q
  set organizacao_id = sub.organizacao_id
  from (
    select
      m.usuario_id,
      min(m.organizacao_id::text)::uuid as organizacao_id
    from public.membros_organizacao m
    group by m.usuario_id
  ) sub
  where q.organizacao_id is null
    and q.criado_por = sub.usuario_id;

  update public.agendamentos a
  set organizacao_id = sub.organizacao_id
  from (
    select
      m.usuario_id,
      min(m.organizacao_id::text)::uuid as organizacao_id
    from public.membros_organizacao m
    group by m.usuario_id
  ) sub
  where a.organizacao_id is null
    and a.criado_por = sub.usuario_id;

  if v_usuario_legado is not null then
    update public.clientes c
    set organizacao_id = sub.organizacao_id
    from (
      select min(m.organizacao_id::text)::uuid as organizacao_id
      from public.membros_organizacao m
      where m.usuario_id = v_usuario_legado
    ) sub
    where c.organizacao_id is null
      and sub.organizacao_id is not null;

    update public.quadros q
    set organizacao_id = sub.organizacao_id
    from (
      select min(m.organizacao_id::text)::uuid as organizacao_id
      from public.membros_organizacao m
      where m.usuario_id = v_usuario_legado
    ) sub
    where q.organizacao_id is null
      and sub.organizacao_id is not null;

    update public.agendamentos a
    set organizacao_id = sub.organizacao_id
    from (
      select min(m.organizacao_id::text)::uuid as organizacao_id
      from public.membros_organizacao m
      where m.usuario_id = v_usuario_legado
    ) sub
    where a.organizacao_id is null
      and sub.organizacao_id is not null;
  end if;

  if exists (
    select 1
    from public.clientes
    where organizacao_id is null
  ) then
    raise exception 'Migração incompleta: existem clientes sem organizacao_id';
  end if;

  if exists (
    select 1
    from public.quadros
    where organizacao_id is null
  ) then
    raise exception 'Migração incompleta: existem quadros sem organizacao_id';
  end if;

  if exists (
    select 1
    from public.agendamentos
    where organizacao_id is null
  ) then
    raise exception 'Migração incompleta: existem agendamentos sem organizacao_id';
  end if;

  alter table public.clientes alter column organizacao_id set not null;
  alter table public.quadros alter column organizacao_id set not null;
  alter table public.agendamentos alter column organizacao_id set not null;
exception
  when undefined_table then null;
  when undefined_column then null;
end
$$;

-- ---------------------------------------------------------------------------
-- helpers internos de organização
-- ---------------------------------------------------------------------------
create or replace function private.eh_membro_organizacao(
  p_usuario_id uuid,
  p_organizacao_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.membros_organizacao m
    where m.usuario_id = p_usuario_id
      and m.organizacao_id = p_organizacao_id
  );
$$;

create or replace function private.assert_membro_organizacao(
  p_usuario_id uuid,
  p_organizacao_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_usuario_id is null then
    raise exception 'Usuário não autenticado';
  end if;

  if p_organizacao_id is null then
    raise exception 'Organização é obrigatória';
  end if;

  if not private.eh_membro_organizacao(p_usuario_id, p_organizacao_id) then
    raise exception 'Usuário não pertence à organização';
  end if;

  if not exists (
    select 1
    from public.organizacoes o
    where o.id = p_organizacao_id
      and o.ativa = true
  ) then
    raise exception 'Organização inativa';
  end if;
end;
$$;

create or replace function private.eh_admin_organizacao(
  p_usuario_id uuid,
  p_organizacao_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.membros_organizacao m
    where m.usuario_id = p_usuario_id
      and m.organizacao_id = p_organizacao_id
      and m.papel in ('proprietario', 'admin')
  );
$$;

create or replace function private.assert_admin_organizacao(
  p_usuario_id uuid,
  p_organizacao_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.assert_membro_organizacao(p_usuario_id, p_organizacao_id);

  if not private.eh_admin_organizacao(p_usuario_id, p_organizacao_id) then
    raise exception 'Permissão insuficiente na organização';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- permissões: helpers internos inacessíveis via API REST
-- ---------------------------------------------------------------------------
revoke all on all functions in schema private from public;
revoke all on all functions in schema private from anon;
revoke all on all functions in schema private from authenticated;

alter default privileges in schema private
  revoke all on functions from public;

alter default privileges in schema private
  revoke all on functions from anon;

alter default privileges in schema private
  revoke all on functions from authenticated;

-- ---------------------------------------------------------------------------
-- permissões: kanban-api (service_role) acessa tabelas em public
-- ---------------------------------------------------------------------------
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;

do $$
declare
  v_tipo record;
begin
  for v_tipo in
    select format('%I.%I', n.nspname, t.typname) as nome
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typtype in ('e', 'c')
  loop
    execute format('grant usage on type %s to service_role', v_tipo.nome);
  end loop;
end $$;

alter default privileges in schema public
  grant all on tables to service_role;

alter default privileges in schema public
  grant all on sequences to service_role;

alter default privileges in schema public
  grant usage on types to service_role;
