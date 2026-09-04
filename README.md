# Aduana 0.0.1

Aduana es una plantilla publica minima para compilar y ejecutar Caddy como gateway HTTPS y reverse proxy parametrizado. No incluye aplicaciones, paneles, secretos, inventarios de servicios, DNS interno ni componentes de red privada.

## Requisitos

- Docker Engine con Compose v2.
- Un registro DNS para `service.example.com` cuando se pruebe fuera de un entorno local.
- Puertos HTTP y HTTPS disponibles en el servidor.

## Compilacion

La imagen fija las versiones y digest de las imagenes base, compila Caddy con el modulo DNS de Cloudflare y ejecuta el proceso final como UID/GID 1000:

```sh
docker compose build caddy
```

El target `vulncheck` permite analizar el binario compilado sin alterar el servicio:

```sh
docker build --target vulncheck -t aduana-vulncheck:0.0.1 .
docker run --rm aduana-vulncheck:0.0.1
```

## Configuracion

1. Crea la configuracion local:

   ```sh
   cp .env.example .env
   ```

2. Ajusta `.env` sin versionar:

   ```dotenv
   ADUANA_VERSION=0.0.1
   BIND_ADDRESS=127.0.0.1
   HTTP_PORT=80
   HTTPS_PORT=443
   SITE_DOMAIN=service.example.com
   UPSTREAM=app:8080
   ACME_EMAIL=admin@example.com
   TLS_MODE=automatic
   CF_API_TOKEN=
   ```

Por defecto, los puertos del host solo se enlazan a `127.0.0.1`. Para aceptar trafico externo de forma explicita, configura `BIND_ADDRESS=0.0.0.0` o una IP concreta. `SITE_DOMAIN` es el nombre atendido por Caddy y `UPSTREAM` es un destino aceptado por `reverse_proxy`; el ejemplo presupone que otro servicio llamado `app` comparte la red `aduana_gateway`.

## TLS

El modo predeterminado, `TLS_MODE=automatic`, deja que Caddy seleccione el challenge ACME apropiado. Requiere que el gateway sea alcanzable publicamente por HTTP o HTTPS.

Para usar DNS-01 con Cloudflare:

```dotenv
TLS_MODE=dns01
CF_API_TOKEN=
```

Asigna `CF_API_TOKEN` solo en el `.env` local. El token debe limitarse a lectura de zona y edicion de DNS para la zona necesaria. DNS-01 no publica automaticamente registros DNS y no sustituye los controles de acceso de red.

## Uso

```sh
docker compose config --quiet
docker compose up -d --build
docker compose logs -f caddy
```

Conecta una aplicacion existente a la red del gateway o adapta `UPSTREAM` a un destino resoluble desde el contenedor. La plantilla no habilita acceso al host ni monta el socket de Docker.

Para detener Aduana sin borrar certificados:

```sh
docker compose down
```

Para borrar tambien el estado TLS persistente:

```sh
docker compose down --volumes
```

## Overlay privado

Los despliegues con varios dominios, rutas, DNS dividido, transporte privado o ajustes por aplicacion deben mantener esos datos en un repositorio o directorio privado separado. Una forma simple es crear fuera de este arbol un `compose.private.yaml`, un `.env` y una carpeta `config/` propios, y superponerlos al archivo publico:

```sh
docker compose \
  --env-file /ruta/privada/.env \
  -f compose.yaml \
  -f /ruta/privada/compose.private.yaml \
  config --quiet
```

El overlay puede reemplazar el volumen de configuracion por `/ruta/privada/config:/etc/caddy:ro`, declarar redes externas y agregar servicios auxiliares. Debe conservar fuera de este repositorio dominios reales, IPs, nombres de servicios, tokens, certificados y catalogos de rutas. Antes de desplegar, revisa la configuracion combinada con `docker compose config` para detectar puertos o variables heredados.

## Seguridad

- La configuracion se monta como solo lectura.
- El contenedor usa un sistema de archivos raiz de solo lectura y capacidades reducidas.
- Caddy se ejecuta como UID/GID 1000, escucha internamente en 8080/8443 y no conserva capacidades Linux.
- Los puertos 80/443 solo se publican en loopback salvo opt-in mediante `BIND_ADDRESS`.
- La API administrativa de Caddy esta deshabilitada.
- La cabecera `Server` se elimina y se agregan cabeceras defensivas basicas.
- Los secretos permanecen fuera del repositorio; `.env`, claves y certificados comunes estan ignorados.
- La autenticacion y autorizacion del upstream siguen siendo responsabilidad de la aplicacion.

## Validacion

El script requiere Docker, construye imagenes temporales, ejecuta `govulncheck` sobre el binario, comprueba el usuario y el modulo Cloudflare, valida Compose y ambos modos TLS, busca patrones sensibles y limpia sus imagenes al salir. No inicia el stack ni modifica servicios activos:

```sh
./scripts/validate.sh
```

## Estructura

```text
.
|-- compose.yaml
|-- Dockerfile
|-- config/
|   |-- Caddyfile
|   `-- tls/
|       |-- automatic.caddy
|       `-- dns01.caddy
|-- scripts/
|   `-- validate.sh
|-- .dockerignore
|-- .env.example
|-- Avances.md
|-- Camino.md
`-- README.md
```

Esta plantilla corresponde a la version `0.0.1`. `Avances.md` delimita su alcance y `Camino.md` documenta las decisiones tecnicas saneadas.
