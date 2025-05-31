
document.addEventListener("DOMContentLoaded", function () {
    const registerForm = document.querySelector('form');
    if (registerForm) {
        registerForm.addEventListener("submit", function (event) {
            event.preventDefault();

            const formData = new FormData(registerForm);
            const action = formData.get("action");

            let url = `http://ws.mybizum.com:8080/ws.php?action=${action}`;
            formData.forEach((value, key) => {
                if (key !== "action") {
                    url += `&${key}=${encodeURIComponent(value)}`;
                }
            });

            const xhr = new XMLHttpRequest();
            xhr.open('GET', url, true);

            xhr.onreadystatechange = function () {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    try {
                        const parser = new DOMParser();
                        const xmlDoc = parser.parseFromString(xhr.responseText, "application/xml");

                        const numError = xmlDoc.querySelector("num_error")?.textContent ?? "0";
                        const userMessage = xmlDoc.querySelector("user_message")?.textContent ?? "Error desconocido.";

                        if (parseInt(numError) !== 0) {
                            // Guardar XML completo en sessionStorage
                            sessionStorage.setItem("responseXML", xhr.responseText);
                            window.location.href = "/pages/error.html";
                        } else {
                            alert("¡Registro exitoso!");
                            window.location.href = "/pages/login.html";
                        }
                    } catch (err) {
                        alert("Error al procesar la respuesta del servidor.");
                    }
                }
            };

            xhr.send();
        });
    }
});
