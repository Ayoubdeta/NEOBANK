document.addEventListener("DOMContentLoaded", function () {
    // Obtener el nombre de usuario desde sessionStorage
    const username = sessionStorage.getItem("login_username");

    if (!username) {
        alert("❌ No se ha iniciado sesión correctamente.");
        return;
    }

    // Mostrar el saldo en la página de inicio
    const balanceElement = document.getElementById("balance");

    // Función para obtener y mostrar el saldo del usuario
    function fetchBalance() {
        const url = `http://ws.mybizum.com:8080/com/ws.php?action=check_balance&username=${encodeURIComponent(username)}`;

        const xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);

        xhr.onreadystatechange = function () {
            if (xhr.readyState === 4 && xhr.status === 200) {
                try {
                    // Procesar la respuesta del servidor (en XML)
                    const parser = new DOMParser();
                    const xmlDoc = parser.parseFromString(xhr.responseText, "text/xml");

                    // Buscar el valor del balance en la respuesta XML
                    const balance = xmlDoc.querySelector("BALANCE")?.textContent;

                    // Si encontramos el balance, mostrarlo
                    if (balance) {
                        balanceElement.textContent = "Tu saldo actual es: " + balance + " €"; // Mostrar saldo con formato
                    } else {
                        const error = xmlDoc.querySelector("Error")?.textContent;
                        balanceElement.textContent = `❌ Error: ${error}`;
                    }
                } catch (error) {
                    balanceElement.textContent = "❌ Error al procesar la respuesta del servidor.";
                }
            } else if (xhr.readyState === 4) {
                balanceElement.textContent = "❌ Error al consultar el saldo.";
            }
        };

        xhr.send();
    }

    // Llamar a la función para obtener el saldo al cargar la página
    fetchBalance();

    // Manejador para el formulario de login
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
                        setCookie("logged_in_user", username, 30);
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

    // Función para establecer una cookie
    function setCookie(name, value, days) {
        const date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        const expires = "expires=" + date.toUTCString();
        document.cookie = name + "=" + value + ";" + expires + ";path=/";
    }

    // Manejo del Logout
    const logoutButton = document.getElementById("logout");
    if (logoutButton) {
        logoutButton.addEventListener("click", function () {
            const xhr = new XMLHttpRequest();
            xhr.open("GET", `http://ws.mybizum.com:8080/com/ws.php?action=logout&username=${encodeURIComponent(username)}`, true);
            xhr.onreadystatechange = function () {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    sessionStorage.clear();
                    window.location.href = "/pages/login.html";
                } else {
                    console.error("Error al hacer logout.");
                }
            };
            xhr.send();
        });
    }
});
