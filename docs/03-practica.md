# 3. Práctica: construir y explorar un ERP

## Propósito

En esta actividad vamos a desplegar una instancia real de ERPNext sin utilizar Docker. El objetivo no es memorizar comandos sino **reconocer los componentes tecnológicos que sostienen un ERP y relacionarlos con sus responsabilidades**.

## Parte A — Antes de instalar

En grupos, dibujen cómo imaginan la arquitectura necesaria para ejecutar ERPNext.

Identifiquen al menos:

- aplicación web;
- base de datos;
- cache/colas;
- backend;
- frontend;
- almacenamiento persistente.

Guarden el dibujo o una captura: lo compararemos con la arquitectura real al finalizar.

## Parte B — Crear el entorno

1. Abrir este repositorio en GitHub.
2. Crear un Codespace.
3. Abrir la terminal.
4. Revisar los recursos disponibles:

```bash
free -h
df -h
```

Registrar cuánta memoria y disco están disponibles inicialmente.

## Parte C — Instalar ERPNext

Ejecutar:

```bash
./scripts/install.sh
```

Mientras el instalador avanza, identificar qué sucede en cada una de sus diez etapas.

No limitarse a esperar: responder durante la ejecución:

1. ¿En qué momento aparece MariaDB y para qué se utilizará?
2. ¿Qué prueba realiza el script para saber si Redis funciona?
3. ¿Qué diferencia observan entre `bench init` y `bench new-site`?
4. ¿En qué momento se descarga ERPNext?
5. ¿Por qué ERPNext se instala *sobre un site*?

## Parte D — Validar la instalación

Ejecutar:

```bash
./scripts/status.sh
```

La evidencia mínima de una instalación correcta es:

- MariaDB operativo;
- Redis respondiendo;
- Bench instalado;
- existencia del site `erp.localhost`;
- aplicaciones `frappe` y `erpnext` instaladas.

Registrar nuevamente:

```bash
free -h
df -h
```

Comparar con los valores iniciales.

## Parte E — Ejecutar ERPNext

```bash
./scripts/start.sh
```

Observar los procesos que aparecen en la terminal. No cerrar esa terminal mientras se utiliza ERPNext.

Abrir el puerto 8000 reenviado por Codespaces.

Ingresar con:

```text
Usuario: Administrator
Contraseña: admin
```

Completar, si aparece, el asistente inicial utilizando datos ficticios.

## Parte F — Explorar el ERP

Localizar dentro de ERPNext ejemplos de al menos tres dominios empresariales diferentes, por ejemplo:

- ventas;
- compras;
- inventario;
- contabilidad;
- recursos humanos.

Para cada uno, identificar un documento o entidad de negocio concreta.

Ejemplo:

```text
Ventas → Sales Order → representa un pedido de un cliente.
```

## Parte G — Volver a la arquitectura

Revisar el dibujo realizado al comienzo.

Construir una segunda versión que incluya explícitamente:

```text
Codespace
MariaDB
Redis
Python
Node/Yarn
Bench
Frappe
ERPNext
Site
Navegador
```

Indicar con flechas qué componentes se comunican entre sí.

## Entrega / evidencia

Entregar una página o slide que contenga:

1. arquitectura final del entorno;
2. captura de ERPNext funcionando;
3. salida relevante de `./scripts/status.sh`;
4. tres entidades/documentos de negocio encontrados;
5. una explicación breve de la diferencia entre **Bench, Frappe, ERPNext y Site**.

## Pregunta de cierre

> Si mañana tuviéramos que instalar este ERP para una empresa real y dejarlo disponible en Internet, ¿qué componentes o decisiones agregaríamos a este laboratorio?

El objetivo es distinguir un **entorno de aprendizaje/desarrollo** de un **deployment productivo**.
