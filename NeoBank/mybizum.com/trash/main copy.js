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
    const form = document.querySelector("form");

    if (form) {
        form.addEventListener("submit", function (event) {
            event.preventDefault();

            const formData = new FormData(form);
            const action = formData.get("action");

            let url = `http://ws.mybizum.com:8080/com/ws.php?action=${action}`;
            formData.forEach((value, key) => {
                if (key !== "action") {
                    url += `&${key}=${encodeURIComponent(value)}`;
                }
            });

            // Usamos fetch para hacer la solicitud
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
                return response.text();  // Convertimos la respuesta a texto
            })
            .then(xmlString => {
                // Verifica que la respuesta se reciba correctamente
                console.log("Respuesta XML del servidor:", xmlString);
                const parser = new DOMParser();
                const xmlDoc = parser.parseFromString(xmlString, "text/xml");
                const numError = xmlDoc.querySelector("num_error")?.textContent;

                sessionStorage.setItem('responseXML', xmlString);

                if (numError === "0") {
                    sessionStorage.setItem('justLoggedIn', 'true');
                    window.location.href = "/pages/dashboard.html";
                } else {
                    window.location.href = "/pages/error.html";
                }
            })
            .catch(error => {
                console.error("Error al hacer login:", error);
                window.location.href = "/pages/error.html";
            });
        });
    }


    const buttons = document.querySelectorAll("[data-action]");

    if (buttons.length > 0) {
        buttons.forEach(button => {
            button.addEventListener("click", function () {
                const action = this.getAttribute("data-action");
                let url = `http://ws.mybizum.com:8080/com/ws.php?action=${action}`;

                const ajaxCall = new clsAjax(url, "app");
                ajaxCall.Call();

                document.addEventListener("_CALL_RETURNED_", function () {
                    sessionStorage.setItem('responseXML', ajaxCall.xml);
                    window.location.href = "/pages/dashboard.html";
                }, { once: true });
            });
        });
    }

    const logoutButton = document.getElementById("logout");
    if (logoutButton) {
        logoutButton.addEventListener("click", function () {
            const xhr = new XMLHttpRequest();
            xhr.open("GET", "http://ws.mybizum.com:8080/com/ws.php?action=logout", true);
            xhr.onreadystatechange = function () {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    sessionStorage.clear();
                    window.location.href = "/pages/login.html";
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
