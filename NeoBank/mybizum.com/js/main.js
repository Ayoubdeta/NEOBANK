console.log("main mayo");

document.addEventListener("DOMContentLoaded", function () {
    
    const form = document.getElementById("loginForm");
    if (form) {
        form.addEventListener("submit", function (event) {
            event.preventDefault();

            const formData = new FormData(form);
            const action = formData.get("action");

            const username = document.getElementById("login_username").value;
            sessionStorage.setItem('login_username', username);

            let url = `http://ws.mybizum.com:8080/ws.php?action=${action}`;
            formData.forEach((value, key) => {
                if (key !== "action") {
                    url += `&${key}=${encodeURIComponent(value)}`;
                }
            });

            const ajax = new clsAjax(url, this);

            document.addEventListener("_CALL_RETURNED_", function () {
                console.log("URL de la solicitud:", url);
                console.log("Respuesta XML del servidor:", ajax.xml);

                const parser = new DOMParser();
                const xmlDoc = parser.parseFromString(ajax.xml, "text/xml");
                const numError = xmlDoc.querySelector("num_error")?.textContent;
                const username = xmlDoc.querySelector("username")?.textContent;
                const ssid = xmlDoc.querySelector("SSID")?.textContent;

                sessionStorage.setItem('responseXML', ajax.xml);

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
            }, { once: true });

            ajax.Call();
        });
    }

    const sendMoneyForm = document.getElementById("sendMoneyForm");
    if (sendMoneyForm) {
        sendMoneyForm.addEventListener("submit", function (e) {
            e.preventDefault();

            const receiver = sendMoneyForm.receiver.value.trim();
            const amount = sendMoneyForm.amount.value;

            if (!receiver || !amount) {
                alert("❗ Todos los campos son obligatorios.");
                return;
            }

            const ssid = sessionStorage.getItem('ssid');
            const url = `http://ws.mybizum.com:8080/ws.php?action=bizum&sender=${encodeURIComponent(ssid)}&receiver=${encodeURIComponent(receiver)}&amount=${amount}`;

            const ajax = new clsAjax(url, this);

            document.addEventListener("_CALL_RETURNED_", function () {
                const responseText = ajax.xml.trim();

                try {
                    const parser = new DOMParser();
                    const xmlDoc = parser.parseFromString(responseText, "application/xml");

                    const messageNodes = xmlDoc.querySelectorAll("ws_response message");

                    if (messageNodes.length > 0) {
                        let messages = [];
                        messageNodes.forEach(msgNode => {
                            messages.push(msgNode.textContent.trim());
                        });
                        alert(messages.join("\n"));
                    } else {
                        alert(responseText);
                    }
                } catch (err) {
                    alert(responseText);
                }
            }, { once: true });

            ajax.Call();
        });
    }

    function setCookie(name, value, days) {
        const date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        const expires = "expires=" + date.toUTCString();
        document.cookie = name + "=" + value + ";" + expires + ";path=/";
    }

    function getCookie(name) {
        const value = `; ${document.cookie}`;
        const parts = value.split(`; ${name}=`);
        if (parts.length === 2) return parts.pop().split(';').shift();
        return null;
    }

    const logoutButton = document.getElementById("logout");
    if (logoutButton) {
        logoutButton.addEventListener("click", function () {
            console.log("Botón logout clicado");

            const ssid = sessionStorage.getItem('ssid');
            const url = "http://ws.mybizum.com:8080/ws.php?action=logout&ssid=" + encodeURIComponent(ssid);

            const ajax = new clsAjax(url, this);

            document.addEventListener("_CALL_RETURNED_", function () {
                console.log("Logout exitoso. Limpiando sessionStorage y redirigiendo.");
                sessionStorage.clear();
                window.location.href = "/pages/login.html";
            }, { once: true });

            ajax.Call();
        });
    }
});
