-- ============================================================
-- Municipalidad Distrital de Río Negro — esquema Supabase
-- Ejecuta esto completo en: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- Tabla de publicaciones (sección "Publicidad y Contenido")
create table if not exists publicaciones (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text,
  body text,
  category text not null default 'noticia', -- comunicado | noticia | obra | actividad | cultura
  tags text[] default '{}',
  images text[] default '{}',       -- URLs de Supabase Storage
  link_url text,
  button_text text,
  status text not null default 'draft',  -- draft | published | archived
  scheduled_at timestamptz,          -- opcional: publicación programada
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Historial de cambios (sección 14 del pedido original)
create table if not exists activity_log (
  id uuid primary key default gen_random_uuid(),
  admin_email text,
  action text not null,       -- created | updated | deleted | restored
  table_name text not null,
  record_id uuid,
  detail jsonb,
  created_at timestamptz not null default now()
);

-- Papelera lógica: en vez de borrar de verdad, marcamos status='archived'
-- y guardamos la fecha; "eliminar definitivamente" sí borra la fila.

-- ============================================================
-- SEGURIDAD (Row Level Security) — esto es lo que hace que la
-- contraseña "no esté en el código": la regla vive en la base de datos.
-- ============================================================
alter table publicaciones enable row level security;
alter table activity_log enable row level security;

-- Cualquier visitante del sitio puede LEER solo lo publicado
create policy "publico_lee_publicadas"
  on publicaciones for select
  using (status = 'published');

-- Solo un usuario autenticado (tú, con tu login) puede crear/editar/borrar
create policy "admin_gestiona_todo"
  on publicaciones for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

create policy "admin_lee_log"
  on activity_log for select
  using (auth.role() = 'authenticated');

create policy "admin_escribe_log"
  on activity_log for insert
  with check (auth.role() = 'authenticated');

-- ============================================================
-- Storage: bucket para imágenes de publicaciones
-- Ve a Supabase Dashboard → Storage → Create bucket → nombre: "publicaciones"
-- Márcalo como "Public bucket" para que las imágenes se vean en el sitio.
-- ============================================================
