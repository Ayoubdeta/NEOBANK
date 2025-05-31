let usernameGuardada;

// Función para verificar la fortaleza de la contraseña de manera dinámica
async function checkPasswordStrength() {
    const password = document.getElementById('password').value;
    const resultDiv = document.getElementById('passwordStrengthResult');

    if (password.length > 0) {
        try {
            let xhr = new XMLHttpRequest();
            xhr.open("GET", "http://ws.mybizum.com:8080/com/ws.php?action=register&password=" + encodeURIComponent(password), true);

            xhr.onreadystatechange = function () {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    resultDiv.innerHTML = xhr.responseText;
                }
            };

            xhr.send();
        } catch (error) {
            resultDiv.innerHTML = 'Error al verificar la contraseña.';
        }
    } else {
        resultDiv.innerHTML = '';
    }
}

document.addEventListener("DOMContentLoaded", function () {
    const form = document.getElementById("loginForm");

    if (form) {
        form.addEventListener("submit", function (event) {
            event.preventDefault();  // Prevenir el envío estándar del formulario

            const formData = new FormData(form);
            const action = formData.get("action");
            

            usernameGuardada = document.getElementById("login_username").value;
            sessionStorage.setItem('login_username', usernameGuardada);
            
            

            let url = `http://ws.mybizum.com:8080/com/ws.php?action=${action}`;
            formData.forEach((value, key) => {
                if (key !== "action") {
                    url += `&${key}=${encodeURIComponent(value)}`;
                }
            });

            // Usamos XMLHttpRequest para hacer la solicitud al servidor
            const xhr = new XMLHttpRequest();
            xhr.open('GET', url, true);

            // Escuchar la respuesta
            xhr.onreadystatechange = function () {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    // Mostrar la URL y la respuesta XML en la consola
                    console.log("URL de la solicitud:", url);
                    console.log("Respuesta XML del servidor:", xhr.responseText);

                    const parser = new DOMParser();
                    const xmlDoc = parser.parseFromString(xhr.responseText, "text/xml");
                    const numError = xmlDoc.querySelector("num_error")?.textContent;
                    const username = xmlDoc.querySelector("username")?.textContent;
                    const ssid = xmlDoc.querySelector("SSID")?.textContent;

                    // Almacenamos la respuesta XML en sessionStorage
                    sessionStorage.setItem('responseXML', xhr.responseText);

                    // Guardar el nombre de usuario en la cookie si el login fue exitoso
                    if (numError === "0" ) {
                        sessionStorage.setItem('ssid', ssid);  // Guardamos el nombre de usuario en sessionStorage
                        setCookie("logged_in_user", username, 30);  // Guardamos el nombre de usuario en una cookie
                    }

                    // Ahora vamos a esperar 2 segundos antes de redirigir para ver la respuesta
                    setTimeout(() => {
                        if (numError === "0") {
                            // Redirige al dashboard si el login fue exitoso
                            window.location.href = "/pages/dashboard.html";
                        } else {
                            // Si hay error, redirige a la página de error
                            window.location.href = "/pages/error.html";
                        }
                    }, 20);  // Retraso de 2 segundos para poder ver la respuesta
                }
            };

            // Enviar la solicitud
            xhr.send();
        });
    }

    // Función para establecer una cookie
    function setCookie(name, value, days) {
        const date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));  // Establecer la fecha de expiración
        const expires = "expires=" + date.toUTCString();
        document.cookie = name + "=" + value + ";" + expires + ";path=/";
    }

    // Manejo de la funcionalidad de Bizum
    
    const sendMoneyForm = document.getElementById("sendMoneyForm");

    if (sendMoneyForm) {
        sendMoneyForm.addEventListener("submit", function(e) {
            e.preventDefault();

            //const sender = sendMoneyForm.sender.value.trim();
            const receiver = sendMoneyForm.receiver.value.trim();
            const amount = sendMoneyForm.amount.value;

            if (!receiver || !amount) {
                alert("❗ Todos los campos son obligatorios.");
                return;
            }

            // Crear una nueva instancia de XMLHttpRequest
            var xhr = new XMLHttpRequest();

            // Preparar los parámetros de la solicitud
            //var url = `http://ws.mybizum.com:8080/com/ws.php?action=bizum&sender=${encodeURIComponent(sender)}&receiver=${encodeURIComponent(receiver)}&amount=${amount}`;
            //var url = `http://ws.mybizum.com:8080/com/ws.php?action=bizum&sender=${(usernameGuardada)}&receiver=${encodeURIComponent(receiver)}&amount=${amount}`;
            const sender = sessionStorage.getItem('login_username');
            var url = `http://ws.mybizum.com:8080/com/ws.php?action=bizum&sender=${encodeURIComponent(sender)}&receiver=${encodeURIComponent(receiver)}&amount=${amount}`;



            // Configurar la solicitud (GET en este caso)
            xhr.open("GET", url, true);

            // Definir qué hacer cuando la solicitud se complete
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    const response = xhr.responseText.trim();

                    if (response === "❗ Todos los campos son obligatorios.") {
                        alert(response);  // Si hay error en los datos, mostramos un mensaje.
                    } else if (response.includes("Bizum de")) {
                        alert(response);  // Si el Bizum fue exitoso, mostramos la confirmación
                    } else {
                        alert(response);
                    }
                } else if (xhr.readyState === 4) {
                    // Error en la solicitud
                    alert("❌ Error de conexión con el servidor.");
                }
            };

            // Enviar la solicitud
            xhr.send();
        });
    }
    
    // Manejo de la funcionalidad de consulta de saldo
const checkBalanceBtn = document.querySelector('button[data-action="check_balance"]');

if (checkBalanceBtn) {
    checkBalanceBtn.addEventListener("click", function () {
        const loggedInUser = getCookie("logged_in_user");

        if (!loggedInUser) {
            alert("❌ No se ha iniciado sesión correctamente.");
            return;
        }

        const url = `http://ws.mybizum.com:8080/com/ws.php?action=check_balance&username=${usernameGuardada}`;
        const xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);

        xhr.onreadystatechange = function () {
            if (xhr.readyState === 4 && xhr.status === 200) {
                try {
                    const response = JSON.parse(xhr.responseText);

                    if (response.error) {
                        alert(response.error);  // Muestra el error si lo hay
                    } else if (response.balance !== undefined) {
                        alert(`Tu saldo es: ${response.balance}`);  // Muestra el saldo
                    }
                } catch (error) {
                    alert("❌ Error al procesar la respuesta del servidor.");
                }
            } else if (xhr.readyState === 4) {
                alert("❌ Error al consultar el saldo.");
            }
        };

        xhr.send();
    });
}

// Función para obtener el valor de una cookie
function getCookie(name) {
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) return parts.pop().split(';').shift();
    return null;
}

    // Manejo de la funcionalidad de Logout
    const logoutButton = document.getElementById("logout");
    if (logoutButton) {
        logoutButton.addEventListener("click", function () {
            // Limpiar la sessionStorage (y cualquier dato relacionado con la sesión)
            sessionStorage.clear();

            // Opcionalmente, enviar una solicitud de logout al servidor
            const xhr = new XMLHttpRequest();
            xhr.open("GET", "http://ws.mybizum.com:8080/com/ws.php?action=logout", true);
            xhr.onreadystatechange = function () {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    // Si el servidor procesa correctamente el logout, redirigimos a login.html
                    window.location.href = "/pages/login.html";
                } else {
                    console.error("Error al hacer logout");
                }
            };
            xhr.send();
        });
    }
});