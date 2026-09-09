# ERPNext en GitHub Codespaces (sin Docker)

Laboratorio didáctico para instalar y ejecutar **ERPNext v15** directamente sobre un GitHub Codespace, evitando un stack Docker de ERPNext para reducir consumo y hacer visible su arquitectura.

## Objetivo

Al finalizar la práctica, el estudiante podrá identificar los componentes del stack ERPNext/Frappe, crear un site, instalar ERPNext y distinguir **Bench**, **Frappe**, **Site** y **ERPNext**.

## Arquitectura

```text
GitHub Codespace (Ubuntu)
       │
       ├── MariaDB
       ├── Redis
       ├── Python
       ├── Node.js / Yarn
       └── Bench
            └── /workspaces/frappe-bench/
                 ├── apps/
                 │    ├── frappe
                 │    └── erpnext
                 └── sites/
                      └── erp.localhost
```

> Codespaces utiliza un dev container para proporcionar la máquina de desarrollo, pero **no usamos las imágenes/Compose de ERPNext**. MariaDB, Redis, Frappe y ERPNext se ejecutan directamente en ese entorno Linux.

## Inicio rápido

1. En GitHub, abrir **Code → Codespaces → Create codespace on main** (o sobre la rama indicada por el docente).
2. Esperar a que VS Code termine de abrir el entorno.
3. En la terminal del repositorio ejecutar:

```bash
bash scripts/install.sh
```

4. Cuando termine:

```bash
bash scripts/start.sh
```

5. Abrir el puerto **8000** desde la pestaña **Ports** de Codespaces.

Credenciales del laboratorio:

```text
Usuario: Administrator
Contraseña: admin
```

Estas credenciales son deliberadamente simples para un entorno descartable. **No son aptas para producción.**

## Comandos

```bash
# instalación (una vez)
bash scripts/install.sh

# iniciar después de crear/reabrir el Codespace
bash scripts/start.sh

# diagnóstico
bash scripts/status.sh

# detener MariaDB y Redis al terminar
bash scripts/stop.sh
```

Los scripts se invocan con `bash` para que la práctica no dependa del bit ejecutable de los archivos descargados mediante GitHub.

## Qué hace la instalación

1. comprueba recursos disponibles;
2. instala dependencias Linux mínimas;
3. configura MariaDB para Frappe;
4. inicia y verifica Redis;
5. instala Node.js, Yarn, `uv` y Bench;
6. crea `/workspaces/frappe-bench` con Frappe `version-15`;
7. crea `erp.localhost`;
8. descarga ERPNext `version-15`;
9. instala ERPNext sobre el site;
10. configura el entorno de desarrollo.

El script evita repetir las operaciones costosas si detecta un bench, site o ERPNext ya existentes. Esto permite reintentarlo después de una instalación interrumpida.

## Conceptos clave

```text
Bench             herramienta que administra el ambiente
Frappe Framework  framework sobre el que se construye ERPNext
ERPNext            aplicación empresarial Frappe
Site               instancia lógica con base de datos/configuración propia
```

Un mismo bench puede alojar múltiples sites, lo que permite introducir el concepto de multitenancy.

## ¿Por qué sin el stack Docker de ERPNext?

El despliegue Docker completo agrega capas y servicios que son útiles en otros escenarios, pero aumentan el footprint y ocultan parte de la arquitectura. En esta práctica queremos observar directamente MariaDB, Redis, Bench, Frappe y ERPNext.

No instalamos Nginx, Supervisor ni TLS: usamos `bench start` y el port forwarding de Codespaces porque el objetivo es **docencia/desarrollo**, no producción.

## Estructura

```text
.
├── .devcontainer/
│   └── devcontainer.json
├── docs/
│   ├── 01-arquitectura.md
│   ├── 02-instalacion.md
│   └── 03-practica.md
├── scripts/
│   ├── install.sh
│   ├── start.sh
│   ├── stop.sh
│   └── status.sh
└── README.md
```

## Documentación

- [1. Arquitectura](docs/01-arquitectura.md)
- [2. Instalación paso a paso](docs/02-instalacion.md)
- [3. Práctica para estudiantes](docs/03-practica.md)

## Alcance y seguridad

Este repositorio está orientado exclusivamente a **desarrollo, demostración y docencia**. No constituye una guía de producción: faltan, entre otras cosas, proxy web, TLS, gestión productiva de procesos, backups, hardening, observabilidad y gestión segura de secretos.

## Versiones objetivo

- Frappe: `version-15`
- ERPNext: `version-15`

Fijar las ramas reduce la variabilidad de la práctica durante el cursado.
