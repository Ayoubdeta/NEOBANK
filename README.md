# NEOBANK
Trabajo final de M07. 
NeoBank - Aplicación Web Full Stack con Sistema de Transferencias Basado en Blockchain

Este proyecto es una aplicación web de banca digital (NeoBank) desarrollada como parte del ciclo formativo de Desarrollo de Aplicaciones Web (DAW). Su objetivo principal es simular el funcionamiento de una banca en línea moderna, con funcionalidades clave como registro, login de usuarios y envío de dinero, integrando tecnologías de desarrollo web, contenedores Docker y un sistema de blockchain para validar transferencias.

🚀 Funcionalidades principales
  -Registro e inicio de sesión de usuarios.
  -Dashboard personal tras iniciar sesión, con distintas funcionalidades.
  -Sistema de transferencias entre usuarios, verificado mediante una blockchain interna que garantiza la integridad de cada transacción.
  -Cada transferencia válida genera un nuevo bloque, que se añade a la cadena de forma segura y verificable.

🛠️ Tecnologías y herramientas utilizadas
  Contenedores Docker
    -Contenedor 1 (Apache2 + Backend + Servicios):
      -Servidor web Apache2
      -PHP para la lógica de backend
      -vsftpd para transferencia de archivos desde VS Code
      -Herramientas para conectarse al contenedor de SQL y realizar consultas
    -Contenedor 2 (Base de datos SQL):
      -Motor de base de datos relacional SQL (por ejemplo, MySQL/MariaDB)

Desarrollo
-Visual Studio Code como editor principal
  -Plugin vsftpd para subir archivos directamente al contenedor Apache2
-HTML y CSS para la estructura y estilo de la interfaz
-AJAX para realizar peticiones asíncronas y actualizar partes del sitio sin recargar
-PHP para el backend, gestión de sesiones, validaciones y lógica de negocio
-SQL para:
  -Crear tablas
  -Definir procedimientos almacenados
  -Crear funciones de negocio
-XML como formato de datos en ciertas respuestas, procesado por AJAX

🔐 Blockchain en Transferencias
Una de las características más avanzadas del proyecto es la integración de una blockchain personalizada:
  -Antes de realizar una transferencia, se verifica la validez de la cadena de bloques.
  -Si la blockchain es válida:
    -Se realiza la transferencia entre usuarios.
    -Se genera un nuevo bloque con los datos de la operación.
    -El bloque se añade a la cadena, garantizando la trazabilidad y seguridad.

🧪 Aprendizajes y competencias desarrolladas
Durante este proyecto he consolidado conocimientos y habilidades en:
  -Configuración y despliegue de entornos con Docker
  -Uso de servidores web y servicios como Apache2, PHP, vsftpd
  -Desarrollo full stack: desde la interfaz de usuario hasta la lógica del backend
  -Comunicación cliente-servidor mediante AJAX y XML
  -Diseño e implementación de lógica segura de transferencias mediante blockchain
  -Dominio de SQL avanzado, incluyendo procedimientos y funciones

🔗 Estado del proyecto
✅ Proyecto finalizado como entrega académica.
🛠️ Abierto a mejoras y refactorización.

📧 Contacto
Si quieres saber más sobre este proyecto o tienes alguna sugerencia, no dudes en contactarme vía GitHub o por correo ayoubajtirah@gmail.com
