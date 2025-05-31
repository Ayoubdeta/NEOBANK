# 🏦 NEOBANK

**Trabajo final de M07 - Desarrollo de Aplicaciones Web (DAW)**  
**NeoBank - Aplicación Web Full Stack con Sistema de Transferencias Basado en Blockchain**

Este proyecto es una **aplicación web de banca digital (NeoBank)** desarrollada como parte del ciclo formativo de **Desarrollo de Aplicaciones Web (DAW)**. Su objetivo principal es simular el funcionamiento de una banca en línea moderna, con funcionalidades clave como **registro, login de usuarios y envío de dinero**, integrando tecnologías de desarrollo web, contenedores **Docker** y un sistema de **blockchain** para validar transferencias.  
Además, el backend ha sido estructurado de forma orientada a objetos, haciendo uso de **clases y principios de programación modular** para una mejor organización del código.

---

## 🚀 Funcionalidades principales

- Registro e inicio de sesión de usuarios.
- Dashboard personal tras iniciar sesión, con distintas funcionalidades.
- Sistema de transferencias entre usuarios, verificado mediante una **blockchain interna** que garantiza la integridad de cada transacción.
- Cada transferencia válida genera un nuevo bloque, que se añade a la cadena de forma segura y verificable.
- Backend estructurado con **clases y objetos** para una arquitectura más limpia, mantenible y escalable.

---

## 🛠️ Tecnologías y herramientas utilizadas

### 🐳 Contenedores Docker

- **Contenedor 1** (Apache2 + Backend + Servicios):
  - Servidor web **Apache2**
  - **PHP** para la lógica de backend
  - **vsftpd** para transferencia de archivos desde VS Code
  - Herramientas para conectarse al contenedor de SQL y realizar consultas

- **Contenedor 2** (Base de datos SQL):
  - Motor de base de datos relacional: **MySQL** o **MariaDB**

### 🧑‍💻 Desarrollo

- **Visual Studio Code** como editor principal
  - Plugin **vsftpd** para subir archivos directamente al contenedor Apache2
- **HTML** y **CSS** para la estructura y estilo de la interfaz
- **AJAX** para realizar peticiones asíncronas y actualizar partes del sitio sin recargar
- **PHP** para el backend, gestión de sesiones, validaciones y lógica de negocio
- **SQL** para:
  - Crear tablas
  - Definir procedimientos almacenados
  - Crear funciones de negocio
- **XML** como formato de datos en ciertas respuestas, procesado por AJAX

#### 🧱 Backend orientado a objetos

El backend en PHP ha sido diseñado utilizando **clases** para encapsular la lógica de negocio y estructurar el código de manera limpia y reutilizable.  
Ejemplos de clases implementadas:

- `User`: gestión de usuarios (registro, login, consulta de saldo)
- `Transaction`: validación y ejecución de transferencias
- `Blockchain` y `Block`: implementación del sistema de cadena de bloques
- `Database`: conexión y consultas a la base de datos

Este enfoque permite separar responsabilidades, facilitar las pruebas y mejorar la mantenibilidad del proyecto.

---

## 🔐 Blockchain en Transferencias

Una de las características más avanzadas del proyecto es la integración de una **blockchain personalizada**:

- Antes de realizar una transferencia, se **verifica la validez de la cadena de bloques**.
- Si la blockchain es válida:
  - Se realiza la transferencia entre usuarios.
  - Se genera un **nuevo bloque** con los datos de la operación.
  - El bloque se añade a la cadena, garantizando la trazabilidad y seguridad.

---

## 🧪 Aprendizajes y competencias desarrolladas

Durante este proyecto he consolidado conocimientos y habilidades en:

- Configuración y despliegue de **entornos con Docker**
- Uso de **servidores web** y servicios como Apache2, PHP, vsftpd
- Desarrollo **full stack**: desde la interfaz de usuario hasta la lógica del backend
- Comunicación cliente-servidor mediante **AJAX** y **XML**
- Diseño e implementación de lógica segura de transferencias mediante **blockchain**
- Dominio de **SQL avanzado**, incluyendo procedimientos y funciones
- Aplicación de principios de **programación orientada a objetos en PHP**

---

## 🔗 Estado del proyecto

✅ Proyecto finalizado como entrega académica  
🛠️ Abierto a mejoras y refactorización

---

## 📧 Contacto

Si quieres saber más sobre este proyecto o tienes alguna sugerencia, no dudes en contactarme:

- 📬 Email: [ayoubajtirah@gmail.com](mailto:ayoubajtirah@gmail.com)
- 💻 GitHub: [TuPerfil](https://github.com/Ayoubdeta)

---

¡Gracias por visitar el repositorio! ⭐
