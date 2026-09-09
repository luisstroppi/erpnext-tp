# ERPNext en GitHub Codespaces (sin Docker)

Laboratorio didáctico para instalar y ejecutar **ERPNext v15** directamente sobre un GitHub Codespace, evitando Docker para reducir el consumo de memoria, almacenamiento y tiempo de descarga.

## Objetivo

Al finalizar la práctica, el estudiante podrá:

- identificar los componentes principales del stack de ERPNext/Frappe;
- preparar un entorno Linux reproducible en GitHub Codespaces;
- instalar y configurar MariaDB, Redis, Python, Node.js, Yarn y Bench;
- crear un sitio Frappe;
- instalar ERPNext sobre ese sitio;
- iniciar, detener y diagnosticar el entorno;
- comprender la diferencia entre **Bench**, **Frappe**, **Site** y **ERPNext**.

## Arquitectura del laboratorio

```text
GitHub Repository
       │
       ▼
GitHub Codespace
Ubuntu Linux
       │
       ├── MariaDB
       ├── Redis
       ├── Python
       ├── Node.js / Yarn
       └── Bench
            │
            └── frappe-bench/
                 ├── apps/
                 │    ├── frappe
                 │    └── erpnext
                 └── sites/
                      └── erp.localhost
```

## ¿Por qué sin Docker?

La imagen oficial de ERPNext está pensada para despliegues completos y suele involucrar varios servicios/contenedores. En un Codespace pequeño, eso agrega consumo de RAM y disco que no aporta demasiado valor pedagógico para una primera práctica.

En este laboratorio los servicios se ejecutan directamente sobre Linux. Así los estudiantes pueden observar con mayor claridad qué necesita ERPNext para funcionar.

## Requisitos

- Cuenta de GitHub con acceso a Codespaces.
- Codespace basado en este repositorio.
- Recomendado: máquina de al menos 2 cores / 8 GB de RAM si está disponible en tu cuota. El laboratorio intenta funcionar con el menor footprint posible, pero la fase de instalación puede ser intensiva.

## Inicio rápido

Dentro del Codespace:

```bash
./scripts/install.sh
```

Cuando finalice la instalación:

```bash
./scripts/start.sh
```

El servidor de desarrollo de Frappe escucha en el puerto **8000**. Codespaces publicará ese puerto automáticamente.

Credenciales del laboratorio:

```text
Usuario: Administrator
Contraseña: admin
```

> Estas credenciales son deliberadamente simples porque el entorno es descartable y educativo. No deben utilizarse en producción.

## Comandos principales

### Instalar

```bash
./scripts/install.sh
```

El script es idempotente en la medida de lo posible: puede ejecutarse nuevamente para completar una instalación interrumpida.

### Iniciar

```bash
./scripts/start.sh
```

### Detener

```bash
./scripts/stop.sh
```

### Diagnóstico

```bash
./scripts/status.sh
```

## Qué hace `install.sh`

El proceso está dividido en etapas visibles:

1. valida el entorno;
2. instala dependencias del sistema;
3. prepara MariaDB;
4. prepara Redis;
5. instala Node.js, Yarn y Bench;
6. crea `frappe-bench` con Frappe v15;
7. crea el sitio `erp.localhost`;
8. descarga ERPNext v15;
9. instala ERPNext en el sitio;
10. aplica configuración de desarrollo y muestra un resumen final.

## Conceptos clave

### Bench

Bench es la herramienta de administración del entorno Frappe. Permite crear benches, sitios, instalar aplicaciones, ejecutar migraciones y levantar los procesos de desarrollo.

### Frappe Framework

Es el framework web sobre el cual está construido ERPNext.

### Site

Un site representa una instancia lógica con su propia base de datos y configuración. Un mismo bench puede alojar múltiples sites.

### ERPNext

ERPNext es una aplicación Frappe que se instala sobre un site.

```text
Bench
 ├── Frappe Framework
 ├── ERPNext App
 └── Sites
      └── erp.localhost
```

## Estructura del repositorio

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

## Advertencias

Este proyecto está orientado exclusivamente a **desarrollo, demostración y docencia**.

No incluye una configuración de producción con Nginx, Supervisor/systemd, TLS, backups, hardening de MariaDB ni gestión segura de secretos.

## Versión objetivo

La práctica fija explícitamente:

- Frappe: `version-15`
- ERPNext: `version-15`

Esto reduce el riesgo de que cambios en ramas de desarrollo rompan la actividad durante el cursado.

## Documentación de la práctica

- [Arquitectura](docs/01-arquitectura.md)
- [Instalación paso a paso](docs/02-instalacion.md)
- [Consigna para estudiantes](docs/03-practica.md)
