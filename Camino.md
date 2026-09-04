# Camino de Aduana

Este documento resume decisiones tecnicas reutilizables. Deliberadamente no contiene nombres, direcciones, dominios, credenciales, inventarios ni detalles de una instalacion real.

## Separar responsabilidades

Un gateway resulta mas facil de operar cuando cada capa tiene una responsabilidad clara:

- DNS traduce nombres, pero no garantiza conectividad.
- El transporte entrega TCP hasta el gateway, pero no debe decidir rutas HTTP.
- TLS autentica el nombre y protege la conexion.
- Caddy termina TLS y selecciona el upstream mediante SNI y HTTP.
- La aplicacion responde y aplica su propia autenticacion y autorizacion.

Al diagnosticar, conviene comprobar esas capas por separado y en ese orden. Un nombre que no resuelve, un socket inaccesible, un certificado invalido y un `502` son fallos distintos.

## ACME y estado persistente

HTTPS automatico permite que Caddy elija un challenge ACME adecuado cuando el gateway es alcanzable. DNS-01 es util cuando no se desea exponer el puerto de validacion HTTP o se necesitan otras politicas de emision; requiere un modulo DNS y una credencial de alcance minimo.

El volumen de datos de Caddy contiene certificados, claves y estado de cuentas ACME. Debe tratarse como informacion sensible, respaldarse segun la politica del despliegue y conservarse entre actualizaciones. Borrarlo innecesariamente puede provocar reemisiones y limites de la autoridad certificadora.

## Transporte TCP, passthrough y SNI

Una red privada o superpuesta puede transportar TCP hasta el gateway sin terminar TLS. Ese passthrough conserva el ClientHello y SNI, de modo que Caddy sigue siendo el unico punto de terminacion TLS y routing. Un reenviador de capa 4 no emite certificados ni interpreta rutas HTTP.

La plantilla publica no incorpora ese transporte. Si un despliegue lo necesita, debe implementarlo en un overlay privado, con identidad, estado, permisos y exposicion de puertos revisados de forma independiente.

## SSE y WebSocket

Caddy negocia WebSocket de forma nativa desde `reverse_proxy`; imponer cabeceras de upgrade o restringir protocolos globalmente puede romper clientes HTTP normales y no es necesario.

SSE y otros flujos interactivos pueden necesitar `flush_interval -1` para entregar eventos inmediatamente. El ajuste debe limitarse a las rutas o upstreams que realmente transmiten datos, evitando compresion o buffering en esos flujos sin penalizar el resto del trafico.

## DNS y el puerto 53

Ejecutar un DNS auxiliar agrega una superficie operativa distinta al proxy. El puerto 53 usa UDP y TCP, puede estar ocupado por el resolvedor del host y nunca debe publicarse accidentalmente como resolver abierto. Si un despliegue necesita DNS dividido, debe vivir en el overlay privado, enlazarse solo a interfaces autorizadas y limitar tanto las zonas como los clientes permitidos.

La version publica evita administrar DNS. El operador crea los registros necesarios fuera de Aduana y mantiene separadas la resolucion de nombres y la configuracion del reverse proxy.

## Extender sin filtrar operacion

Los dominios reales, destinos, excepciones TLS, rutas de streaming y componentes de transporte pertenecen a archivos privados no versionados en este repositorio. Antes de incorporar una excepcion, se debe documentar en el overlay que la consume, limitar su alcance y validar DNS, transporte, TLS y respuesta del upstream por separado.
