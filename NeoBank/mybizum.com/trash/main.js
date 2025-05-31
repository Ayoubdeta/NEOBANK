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

            let url = `http://ws.mybizum.com:8080/com/ws.php?action=${action}`;
            formData.forEach((value, key) => {
                if (key !== "action") {
                    url += `&${key}=${encodeURIComponent(value)}`;
                }
            });

            // Usamos fetch para hacer la solicitud al servidor
            fetch(url, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/xml'
                }
            })
            .then(response => {
                // Verifica si la solicitud es exitosa
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                console.log("URL de la solicitud:", url);  // Muestra la URL de la solicitud en la consola
                return response.text();  // Convertimos la respuesta a texto
            })
            .then(xmlString => {
                // Verifica que la respuesta se reciba correctamente y la muestra en la consola
                console.log("Respuesta XML del servidor:", xmlString);
                const parser = new DOMParser();
                const xmlDoc = parser.parseFromString(xmlString, "text/xml");
                const numError = xmlDoc.querySelector("num_error")?.textContent;

                // Almacenamos la respuesta XML en sessionStorage
                sessionStorage.setItem('responseXML', xmlString);

                // Añadimos un retraso para que puedas inspeccionar la respuesta
                setTimeout(() => {
                    if (numError === "0") {
                        // Redirige al dashboard si el login fue exitoso
                        window.location.href = "/pages/dashboard.html";
                    } else {
                        // Si hay error, redirige a la página de error
                        window.location.href = "/pages/error.html";
                    }
                }, 2000);  // Retraso de 2 segundos para poder ver la respuesta
            })
            .catch(error => {
                console.error("Error al hacer login:", error);
                window.location.href = "/pages/error.html";
            });
        });
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

    // MOSTRAR MENSAJE EN DASHBOARD SOLO UNA VEZ TRAS INICIAR SESIÓN
    if (window.location.pathname.includes("dashboard.html")) {
        const xmlString = sessionStorage.getItem("responseXML");
        const justLoggedIn = sessionStorage.getItem("justLoggedIn");

        if (xmlString) {
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(xmlString, "text/xml");
            const numError = xmlDoc.querySelector("num_error")?.textContent;
            const userMsg = xmlDoc.querySelector("user_message")?.textContent;
            const infoDiv = document.getElementById("serverInfo");

            if (numError === "0" && justLoggedIn === "true") {
                infoDiv.innerText = `✅ ${userMsg || "Sesión iniciada correctamente."}`;
                sessionStorage.removeItem("justLoggedIn");
            }
        } else {
            // Redirige si no hay datos
            window.location.href = "/pages/login.html";
        }
    }
});