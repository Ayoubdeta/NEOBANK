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

    // No funcional
    function setCookie(name, value, days) {
        const date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        const expires = "expires=" + date.toUTCString();
        document.cookie = name + "=" + value + ";" + expires + ";path=/";
    }

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
            const url = `http://ws.mybizum.com:8080/com/ws.php?action=bizum&sender=${encodeURIComponent(sender)}&receiver=${encodeURIComponent(receiver)}&amount=${amount}`;

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

    // no va
    const checkBalanceBtn = document.querySelector('button[data-action="check_balance"]');
    if (checkBalanceBtn) {
        checkBalanceBtn.addEventListener("click", function () {
            const username = sessionStorage.getItem("login_username");

            if (!username) {
                alert("❌ No se ha iniciado sesión correctamente.");
                return;
            }

            const url = `http://ws.mybizum.com:8080/com/ws.php?action=check_balance&username=${encodeURIComponent(username)}`;
            const xhr = new XMLHttpRequest();
            xhr.open("GET", url, true);

            xhr.onreadystatechange = function () {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);

                        if (response.error) {
                            alert(response.error);
                        } else if (response.balance !== undefined) {
                            alert(`Tu saldo es: ${response.balance}`);
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

    // NO FUNCIONAL
    function getCookie(name) {
        const value = `; ${document.cookie}`;
        const parts = value.split(`; ${name}=`);
        if (parts.length === 2) return parts.pop().split(';').shift();
        return null;
    }


    // MOSTRAR SALDO
    document.addEventListener("DOMContentLoaded", function () {
        // Obtener el nombre de usuario de la sesión
        const username = sessionStorage.getItem("login_username");
    
        // Asegurarse de que el nombre de usuario está presente
        if (!username) {
            alert("❌ No se ha iniciado sesión correctamente.");
            return;
        }
    
        // Elemento donde se mostrará el saldo
        const balanceElement = document.getElementById("userBalance");
    
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
                            balanceElement.textContent = balance + " €"; // Mostrar saldo con formato
                        } else {
                            const error = xmlDoc.querySelector("Error")?.textContent;
                            alert(`❌ Error: ${error}`);
                        }
                    } catch (error) {
                        alert("❌ Error al procesar la respuesta del servidor.");
                    }
                } else if (xhr.readyState === 4) {
                    alert("❌ Error al consultar el saldo.");
                }
            };
    
            xhr.send();
        }
    
        // Llamar a la función para obtener el saldo al cargar la página
        fetchBalance();
    });


    document.addEventListener("DOMContentLoaded", function () {
        // Obtener el nombre de usuario desde sessionStorage
        const username = sessionStorage.getItem("login_username");
      
        if (!username) {
          alert("❌ No se ha iniciado sesión correctamente.");
          return;
        }
      
        // Seleccionar el contenedor donde se mostrará el saldo
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
      });


    
    // Manejo de la funcionalidad de Logout VERSION OLD
    /*
    const logoutButton = document.getElementById("logout");
    if (logoutButton) {
        logoutButton.addEventListener("click", function () {
            // Enviar una solicitud de logout al servidor
            const xhr = new XMLHttpRequest();
            xhr.open("GET", "http://ws.mybizum.com:8080/com/ws.php?action=logout", true);
            xhr.onreadystatechange = function () {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    // Limpiar la sessionStorage después de que el servidor procese el logout
                    sessionStorage.clear();
                    // Redirigimos a login.html
                    window.location.href = "/pages/login.html";
                } else if (xhr.readyState === 4) {
                    console.error("Error al hacer logout");
                }
            };
            xhr.send();
        });
    }
        */

    const logoutButton = document.getElementById("logout");
    if (logoutButton) {
    logoutButton.addEventListener("click", function () {
        console.log("Botón logout clicado"); // <-- AÑADIDO

        const username = sessionStorage.getItem('login_username');

        const xhr = new XMLHttpRequest();
        //xhr.open("GET", "http://ws.mybizum.com:8080/com/ws.php?action=logout", true);
        xhr.open("GET", "http://ws.mybizum.com:8080/com/ws.php?action=logout&username=" + encodeURIComponent(username), true);
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