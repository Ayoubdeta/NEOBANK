
document.addEventListener("DOMContentLoaded", function () {
    
    const form = document.getElementById("loginForm");
    if (form) {
        form.addEventListener("submit", function (event) {
            event.preventDefault();

            const formData = new FormData(form);
            const action = formData.get("action");

            const username = document.getElementById("login_username").value;
            sessionStorage.setItem('login_username', username);

            let url = `http://ws.mybizum.com:8080/com/ws.php?action=${action}`;
            formData.forEach((value, key) => {
                if (key !== "action") {
                    url += `&${key}=${encodeURIComponent(value)}`;
                }
            });

            const xhr = new XMLHttpRequest();
            xhr.open('GET', url, true);

            xhr.onreadystatechange = function () {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    console.log("URL de la solicitud:", url);
                    console.log("Respuesta XML del servidor:", xhr.responseText);

                    const parser = new DOMParser();
                    const xmlDoc = parser.parseFromString(xhr.responseText, "text/xml");
                    const numError = xmlDoc.querySelector("num_error")?.textContent;
                    const username = xmlDoc.querySelector("username")?.textContent;
                    const ssid = xmlDoc.querySelector("SSID")?.textContent;

                    sessionStorage.setItem('responseXML', xhr.responseText);

                    if (numError === "0") {
                        sessionStorage.setItem('ssid', ssid);
                       // setCookie("logged_in_user", username, 30);
                    }

                    setTimeout(() => {
                        if (numError === "0") {
                            window.location.href = "/pages/dashboard.html";
                        } else {
                            window.location.href = "/pages/error.html";
                        }
                    }, 20);
                }
            };

            xhr.send();
        });
    }

    // No funcional
    function setCookie(name, value, days) {
        const date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        const expires = "expires=" + date.toUTCString();
        document.cookie = name + "=" + value + ";" + expires + ";path=/";
    }

    // Funciona
    /*
    const sendMoneyForm = document.getElementById("sendMoneyForm");
    if (sendMoneyForm) {
        sendMoneyForm.addEventListener("submit", function(e) {
            e.preventDefault();

            const receiver = sendMoneyForm.receiver.value.trim();
            const amount = sendMoneyForm.amount.value;

            if (!receiver || !amount) {
                alert("❗ Todos los campos son obligatorios.");
                return;
            }

            const sender = sessionStorage.getItem('login_username');
            const ssid = sessionStorage.getItem('ssid');
            const url = `http://ws.mybizum.com:8080/com/ws.php?action=bizum&sender=${encodeURIComponent(ssid)}&receiver=${encodeURIComponent(receiver)}&amount=${amount}`;

            const xhr = new XMLHttpRequest();
            xhr.open("GET", url, true);

            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    const response = xhr.responseText.trim();

                    if (response === "❗ Todos los campos son obligatorios.") {
                        alert(response);
                    } else if (response.includes("Bizum de")) {
                        alert(response);
                    } else {
                        alert(response);
                    }
                } else if (xhr.readyState === 4) {
                    alert("❌ Error de conexión con el servidor.");
                }
            };

            xhr.send();
        });
    }
    */
   const sendMoneyForm = document.getElementById("sendMoneyForm");
if (sendMoneyForm) {
    sendMoneyForm.addEventListener("submit", function(e) {
        e.preventDefault();

        const receiver = sendMoneyForm.receiver.value.trim();
        const amount = sendMoneyForm.amount.value;

        if (!receiver || !amount) {
            alert("❗ Todos los campos son obligatorios.");
            return;
        }

        const sender = sessionStorage.getItem('login_username');
        const ssid = sessionStorage.getItem('ssid');
        const url = `http://ws.mybizum.com:8080/com/ws.php?action=bizum&sender=${encodeURIComponent(ssid)}&receiver=${encodeURIComponent(receiver)}&amount=${amount}`;

        const xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);

        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4) {
                if (xhr.status === 200) {
                    const responseText = xhr.responseText.trim();

                    try {
                        const parser = new DOMParser();
                        const xmlDoc = parser.parseFromString(responseText, "application/xml");

                        // Buscar todos los nodos <message> dentro de <ws_response>
                        const messageNodes = xmlDoc.querySelectorAll("ws_response message");

                        if (messageNodes.length > 0) {
                            // Concatenar todos los mensajes encontrados
                            let messages = [];
                            messageNodes.forEach(msgNode => {
                                messages.push(msgNode.textContent.trim());
                            });
                            alert(messages.join("\n"));
                        } else {
                            // Si no hay mensajes, mostrar el texto plano
                            alert(responseText);
                        }
                    } catch (err) {
                        // Si falla el parseo, mostrar el texto plano
                        alert(responseText);
                    }
                } else {
                    alert("❌ Error de conexión con el servidor.");
                }
            }
        };

        xhr.send();
    });
}


    

    // NO FUNCIONAL
    function getCookie(name) {
        const value = `; ${document.cookie}`;
        const parts = value.split(`; ${name}=`);
        if (parts.length === 2) return parts.pop().split(';').shift();
        return null;
    }

   
    const logoutButton = document.getElementById("logout");
    if (logoutButton) {
    logoutButton.addEventListener("click", function () {
        console.log("Botón logout clicado"); // <-- AÑADIDO

        const username = sessionStorage.getItem('login_username');
        const ssid = sessionStorage.getItem('ssid');

        const xhr = new XMLHttpRequest();
        //xhr.open("GET", "http://ws.mybizum.com:8080/com/ws.php?action=logout", true);
        xhr.open("GET", "http://ws.mybizum.com:8080/com/ws.php?action=logout&ssid=" + encodeURIComponent(ssid), true);
        xhr.onreadystatechange = function () {
            console.log("Estado de la solicitud:", xhr.readyState, "Código de estado:", xhr.status);
            if (xhr.readyState === 4) {
                if (xhr.status === 200) {
                    console.log("Logout exitoso. Limpiando sessionStorage y redirigiendo.");
                    sessionStorage.clear();
                    window.location.href = "/pages/login.html";
                } else {
                    console.error("Error al hacer logout. Código de estado:", xhr.status);
                }
            }
        };

        xhr.send();
    });
}
});