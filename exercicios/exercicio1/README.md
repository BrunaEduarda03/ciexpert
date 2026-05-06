## Execute

```bash
chmod +x gen-prj.sh
./gen-prj.sh
```

## Q1) Que mensagem saiu?

Error: please provide the project name.
Usage: ./gen-prj.sh <project_name>

## Q2) O que fazer para resolver?

```bash
chmod +x scripts/gen-prj.sh
./scripts/gen-prj.sh hello

Project 'hello' successfully created inside prj/ e cria
```

prj/
└── hello/
├── rtl/
├── tb/
└── docs/

## Q3) O que acontece se executar duas vezes?

Error: project 'hello' already exists.
