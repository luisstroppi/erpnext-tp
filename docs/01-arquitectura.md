# 1. Arquitectura del laboratorio

## La pregunta de partida

Antes de instalar ERPNext conviene responder una pregunta: **¿qué necesita realmente un ERP web para ejecutarse?**

En esta práctica evitamos Docker deliberadamente. El objetivo no es reproducir una arquitectura de producción, sino hacer visibles las piezas que normalmente quedan ocultas dentro de contenedores.

## Componentes

```text
Usuario / navegador
       │
       │ HTTP :8000
       ▼
Frappe / ERPNext
       │
       ├──────────────► MariaDB
       │                datos persistentes
       │
       └──────────────► Redis
                        cache / colas
```

El entorno también utiliza:

- **Python**: runtime principal del backend Frappe.
- **Node.js + Yarn**: toolchain de assets y frontend.
- **Bench**: CLI para administrar Frappe.
- **MariaDB**: base de datos relacional.
- **Redis**: infraestructura de cache y procesamiento asíncrono.

## Bench no es ERPNext

Esta distinción es central:

```text
frappe-bench/
├── apps/
│   ├── frappe/       ← framework
│   └── erpnext/      ← aplicación ERP
└── sites/
    └── erp.localhost ← instancia / tenant
```

**Bench** administra el ambiente.

**Frappe** es el framework.

**ERPNext** es una aplicación construida sobre Frappe.

**Site** es una instancia lógica con configuración y base de datos propias.

## Multitenancy

Un mismo bench puede alojar más de un site:

```text
frappe-bench/
└── sites/
    ├── empresa-a.localhost
    ├── empresa-b.localhost
    └── empresa-c.localhost
```

Cada site puede tener su propia base de datos y conjunto de aplicaciones instaladas.

## Desarrollo versus producción

Este laboratorio usa `bench start`, que levanta los procesos requeridos para desarrollo. Es apropiado para una clase, pero **no es una arquitectura de producción**.

Una instalación productiva requiere decisiones adicionales sobre proxy web, TLS, administración de procesos, backups, observabilidad, seguridad, secretos, actualización y recuperación ante fallos.

## ¿Por qué Codespaces?

Codespaces nos ofrece una máquina Linux reproducible asociada al repositorio. El alumno puede destruirla y recrearla sin modificar su computadora personal.

El repositorio define solamente un contenedor de desarrollo Linux liviano. **ERPNext no se ejecuta en un stack Docker Compose**: MariaDB, Redis, Frappe y ERPNext se instalan directamente dentro del Codespace.

## Preguntas para discutir

1. ¿Qué responsabilidades cumple MariaDB y cuáles Redis?
2. ¿Qué diferencia hay entre Frappe y ERPNext?
3. ¿Por qué un site puede considerarse un tenant?
4. ¿Qué ventajas aporta Docker en producción que estamos resignando en este laboratorio?
5. ¿Qué recursos adicionales necesitaríamos para transformar este laboratorio en un deployment productivo?
