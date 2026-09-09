# 2. Instalación paso a paso

Esta página explica lo que automatiza `scripts/install.sh`. Durante la clase conviene recorrer estas etapas conceptualmente antes de ejecutar el script completo.

## 1. Crear el Codespace

Desde el repositorio, crear un Codespace sobre la rama de la práctica. GitHub leerá `.devcontainer/devcontainer.json` y preparará Ubuntu.

El puerto 8000 queda declarado para que Codespaces pueda reenviarlo cuando Frappe comience a escuchar.

## 2. Dependencias del sistema

El instalador agrega un conjunto mínimo de paquetes para compilar dependencias Python y ejecutar los servicios:

- MariaDB Server/Client y headers de desarrollo;
- Redis;
- Python 3, headers y `venv`;
- compilador y bibliotecas requeridas por dependencias de Frappe;
- Git, curl y certificados.

No instalamos Nginx, Supervisor ni Docker porque no son necesarios para este laboratorio de desarrollo.

## 3. MariaDB

Frappe almacena los datos del site en MariaDB. Configuramos UTF-8 completo (`utf8mb4`) para evitar problemas con caracteres Unicode.

El laboratorio utiliza una contraseña de root conocida para poder crear el site sin interacción:

```text
root
```

Esto **no es una práctica de seguridad válida para producción**.

## 4. Redis

Redis participa en cache y colas/procesamiento asíncrono. Una comprobación mínima es:

```bash
redis-cli ping
```

Respuesta esperada:

```text
PONG
```

## 5. Node, Yarn y Bench

Frappe necesita la toolchain JavaScript para construir assets. El laboratorio instala Node.js 20 y Yarn.

Bench se instala como herramienta aislada mediante `uv`.

Comprobaciones:

```bash
node --version
yarn --version
bench --version
```

## 6. Crear el bench

Conceptualmente, el comando importante es:

```bash
bench init --frappe-branch version-15 /workspaces/frappe-bench
```

Esto crea el entorno Python, descarga Frappe y prepara la estructura del bench.

> Esta suele ser una de las etapas de mayor consumo de tiempo, disco y memoria.

## 7. Crear el site

```bash
bench new-site erp.localhost
```

El script proporciona las credenciales automáticamente.

En este momento ya existe una instancia Frappe, pero **ERPNext todavía no está instalado**.

## 8. Descargar ERPNext

```bash
bench get-app --branch version-15 erpnext https://github.com/frappe/erpnext
```

Esto agrega el código de ERPNext al directorio `apps/` del bench.

## 9. Instalar ERPNext en el site

```bash
bench --site erp.localhost install-app erpnext
```

Este comando modifica el site: crea DocTypes, módulos, configuraciones y demás estructuras requeridas por ERPNext.

## 10. Ejecutar

Desde el repositorio de la práctica:

```bash
./scripts/start.sh
```

Internamente se inician MariaDB y Redis y luego se ejecuta:

```bash
bench start
```

El proceso permanece en primer plano para que el estudiante pueda observar los logs.

## 11. Abrir ERPNext

Codespaces detectará el puerto 8000. Abrir el puerto reenviado desde la interfaz de Codespaces.

Credenciales:

```text
Administrator
admin
```

La primera entrada puede mostrar el asistente inicial de configuración de ERPNext.

## 12. Diagnóstico

Ante un problema ejecutar:

```bash
./scripts/status.sh
```

Verifica servicios, runtimes, bench, site, ERPNext, memoria y espacio en disco.

## Reabrir un Codespace existente

No hace falta reinstalar ERPNext. Los archivos permanecen en el Codespace, pero los servicios pueden estar detenidos.

Ejecutar simplemente:

```bash
./scripts/start.sh
```

## Reintentar una instalación interrumpida

El instalador comprueba la existencia de bench, site y aplicación antes de repetir las operaciones más costosas. Por eso el primer intento ante un fallo debería ser:

```bash
./scripts/status.sh
./scripts/install.sh
```
