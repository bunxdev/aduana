# Avances

## 0.0.1

Primera version publica y saneada de Aduana.

### Incluido

- Gateway Caddy reducido a un unico reverse proxy parametrizado.
- HTTPS automatico como opcion predeterminada.
- DNS-01 opcional mediante un modulo de proveedor compilado en la imagen.
- Configuracion reproducible con Docker Compose y persistencia separada para datos y estado.
- Endurecimiento basico del contenedor y cabeceras HTTP defensivas.
- Validacion automatizada de Compose, Caddy y patrones sensibles.
- Documentacion basada exclusivamente en dominios reservados y valores ficticios.

### Historial saneado

La referencia privada evoluciono desde un proxy inicial hacia certificados publicos con DNS-01, multiples rutas, resolucion DNS auxiliar, conectividad superpuesta y ajustes para trafico persistente. Para esta plantilla publica se conservaron solo las conclusiones reutilizables:

- Separar la obtencion de certificados de la topologia privada.
- Mantener DNS-01 opcional y usar HTTPS automatico cuando sea suficiente.
- Permitir que `reverse_proxy` gestione HTTP, streaming y WebSocket sin limitar protocolos globalmente.
- Parametrizar un unico destino en vez de publicar un inventario operativo.
- Excluir sidecars, DNS internos, interfaces de usuario, vaults y rutas especificas.

No se trasladaron nombres internos, direcciones, dominios reales, credenciales, topologias ni contenido operativo de las referencias.
