
function fetchBalanceAndDisplay(selectorId = "balance") {
    const username = sessionStorage.getItem("login_username");
    const ssid = sessionStorage.getItem("ssid");
    if (!username) {
        console.warn("❌ No se ha iniciado sesión correctamente.");
        return;
    }

    const balanceElement = document.getElementById(selectorId);
    if (!balanceElement) {
        console.warn(`⚠️ No se encontró el elemento con ID '${selectorId}'`);
        return;
    }

    //const url = `http://ws.mybizum.com:8080/com/ws.php?action=check_balance&username=${encodeURIComponent(ssid)}`;
    const url = `http://ws.mybizum.com:8080/ws.php?action=check_balance&ConnectionId=${encodeURIComponent(ssid)}`;


    // Crear instancia de clsAjax
    const ajax = new clsAjax(url, null);
    ajax.Call();

    // Manejar la respuesta cuando esté disponible
    document.addEventListener("_CALL_RETURNED_", function handleResponse() {
        const response = ajax.xml.trim();
        console.log("Respuesta del servidor (balance):", response);

        try {
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(response, "text/xml");
            const balance = xmlDoc.querySelector("BALANCE")?.textContent;

            if (balance) {
                balanceElement.textContent = ` ${balance} €`;
            } else {
                const error = xmlDoc.querySelector("Error")?.textContent || "Error desconocido";
                balanceElement.textContent = `❌ Error: ${error}`;
            }
           /*const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(response, "text/xml");
            const balance = xmlDoc.querySelector("balance")?.textContent;

            if (balance) {
                balanceElement.textContent = ` ${balance} €`;
            } else {
                const error = xmlDoc.querySelector("message")?.textContent || "Error desconocido";
                balanceElement.textContent = `❌ Error: ${error}`;
            }
            */
        } catch (error) {
            balanceElement.textContent = "❌ Error al procesar la respuesta del servidor.";
        }

        // Limpiar el listener para evitar múltiples llamadas
        document.removeEventListener("_CALL_RETURNED_", handleResponse);
    });
}

document.addEventListener("DOMContentLoaded", function () {
    fetchBalanceAndDisplay("balance");
});
