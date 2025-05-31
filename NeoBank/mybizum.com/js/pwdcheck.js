// Función para verificar la fortaleza de la contraseña de manera dinámica

async function checkPasswordStrength() {
    const password = document.getElementById('password').value;
    const resultDiv = document.getElementById('passwordStrengthResult');

    if (password.length > 0) {
        try {
            let xhr = new XMLHttpRequest();
            xhr.open("GET", "http://ws.mybizum.com:8080/ws.php?action=register&password=" + encodeURIComponent(password), true);

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
    

