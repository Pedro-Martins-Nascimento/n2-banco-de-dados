create extension if not exists "uuid-ossp";

create table usuarios_senhas (
    id uuid primary key default uuid_generate_v4(),
    nome varchar(100) not null,
    email varchar(255) unique not null,
    data_criacao date default current_date,
    hash varchar(255) not null
);
 
create table acessos (
    id uuid primary key default uuid_generate_v4(),
    nome varchar(50) not null
);
 
create table escolas (
    id uuid primary key default uuid_generate_v4(),
    cnpj varchar(20) unique not null,
    nome varchar(150) not null,
    endereco varchar(255),
    fk_usuarios_senhas_id uuid not null
);
 
create table alunos (
    id uuid primary key references usuarios_senhas(id) on delete cascade,
    nome varchar(100) not null,
    cpf varchar(14) unique not null,
    data_nascimento date,
    sexo varchar(10)
);
 
create table questoes (
    id uuid primary key default uuid_generate_v4(),
    texto jsonb not null,
    alternativa_correta integer not null,
    alternativas jsonb not null
);
 
create table simulado (
    id uuid primary key default uuid_generate_v4(),
    titulo varchar(150) not null
);
 
create table escolas_alunos (
    id uuid primary key default uuid_generate_v4(),
    fk_escolas_id uuid not null,
    fk_alunos_id uuid not null,
    unique(fk_escolas_id, fk_alunos_id)
);
 
create table sessao_simulado (
    id uuid primary key default uuid_generate_v4(),
    data_inicio timestamp default now(),
    data_fim timestamp,
    status varchar(50) default 'em andamento',
    qnt_questoes integer default 0,
    qnt_acertos integer default 0,
    fk_usuarios_senhas_id uuid not null,
    fk_simulado_id uuid not null
);
 
create table respostas (
    id uuid primary key default uuid_generate_v4(),
    alternativa_escolhida integer not null,
    acertou boolean not null,
    momento_resposta timestamp default now(),
    fk_sessao_simulado_id uuid not null,
    fk_questoes_id uuid not null,
    unique(fk_sessao_simulado_id, fk_questoes_id)
);
 
create table usuarios_acessos (
    fk_usuarios_senhas_id uuid not null,
    fk_acessos_id uuid null
);
 
create table simulado_questoes (
    fk_questoes_id uuid not null,
    fk_simulado_id uuid null
);
 
alter table escolas add constraint fk_escolas_usuarios
    foreign key (fk_usuarios_senhas_id) references usuarios_senhas(id) on delete cascade;
 
alter table escolas_alunos add constraint fk_escolas_alunos_escolas
    foreign key (fk_escolas_id) references escolas(id) on delete cascade;
 
alter table escolas_alunos add constraint fk_escolas_alunos_alunos
    foreign key (fk_alunos_id) references alunos(id) on delete cascade;
 
 
alter table sessao_simulado add constraint fk_sessao_simulado_usuarios
    foreign key (fk_usuarios_senhas_id) references usuarios_senhas(id) on delete cascade;
 
alter table sessao_simulado add constraint fk_sessao_simulado_simulado
    foreign key (fk_simulado_id) references simulado(id) on delete cascade;
 
alter table respostas add constraint fk_respostas_sessao
    foreign key (fk_sessao_simulado_id) references sessao_simulado(id) on delete cascade;
 
alter table respostas add constraint fk_respostas_questao
    foreign key (fk_questoes_id) references questoes(id) on delete cascade;
 
alter table usuarios_acessos add constraint fk_usuarios_acessos_usuarios
    foreign key (fk_usuarios_senhas_id) references usuarios_senhas(id) on delete cascade;
 
alter table usuarios_acessos add constraint fk_usuarios_acessos_acessos
    foreign key (fk_acessos_id) references acessos(id) on delete cascade;
 
alter table simulado_questoes add constraint fk_simulado_questoes_questao
    foreign key (fk_questoes_id) references questoes(id) on delete cascade;
 
alter table simulado_questoes add constraint fk_simulado_questoes_simulado
    foreign key (fk_simulado_id) references simulado(id) on delete cascade;
 
create or replace function inicializar_perfil_padrao()
returns trigger as $$
begin
    insert into usuarios_acessos (fk_usuarios_senhas_id, fk_acessos_id)
    values (new.id, (select id from acessos where nome = 'aluno' limit 1));
    return new;
end;
$$ language plpgsql;
 
create trigger trigger_novo_usuario
after insert on usuarios_senhas
for each row execute function inicializar_perfil_padrao();
 
alter table usuarios_senhas enable row level security;
alter table escolas enable row level security;
alter table escolas_alunos enable row level security;
alter table sessao_simulado enable row level security;
alter table respostas enable row level security;
alter table questoes enable row level security;
 
create policy "questoes acessiveis a todos" on questoes
    for select to authenticated using (true);
 
create policy "alunos acessam apenas suas sessoes" on sessao_simulado
    for all to authenticated
    using (fk_usuarios_senhas_id = auth.uid()::uuid);
 
create policy "admin controla apenas sua escola" on escolas
    for all to authenticated
    using (fk_usuarios_senhas_id = auth.uid()::uuid);
 
create policy "alunos veem suas matriculas" on escolas_alunos
    for select to authenticated
    using (fk_alunos_id = auth.uid()::uuid);
