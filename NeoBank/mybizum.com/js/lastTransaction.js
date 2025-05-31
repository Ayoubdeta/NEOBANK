document.addEventListener("DOMContentLoaded", function () {
    // Obtener el nombre de usuario desde sessionStorage
    
    const username = sessionStorage.getItem('login_username');
    const ssid = sessionStorage.getItem('ssid');

    // Verificar que el nombre de usuario esté presente
    if (!username) {
        alert("No se ha iniciado sesión.");
        return;
    }

    // Construir la URL para la llamada AJAX al último movimiento
    //const url = `http://ws.mybizum.com:8080/com/ws.php?action=get_last_transactions&username=${encodeURIComponent(username)}`;
    const url = `http://ws.mybizum.com:8080/ws.php?action=get_last_transactions&ssid=${encodeURIComponent(ssid)}`;

    // Crear una instancia de clsAjax
    const ajax = new clsAjax(url, null);
    ajax.Call();

    // Escuchar el evento personalizado disparado por clsAjax cuando se recibe la respuesta
    document.addEventListener("_CALL_RETURNED_", function () {
        const response = ajax.xml.trim();
        console.log("Respuesta del servidor:", response);

        const content = document.getElementById("lastTransactionContent");
        if (!content) {
            console.warn("Elemento #lastTransactionContent no encontrado.");
            return;
        }

        if (response) {
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(response, "text/xml");

            const error = xmlDoc.querySelector('Error');
            if (error) {
                content.innerHTML = `<p class="error">❌ Error: ${error.textContent}</p>`;
                return;
            }

            const transaction = xmlDoc.querySelector('Transaction');
            if (transaction) {
                const id = transaction.querySelector('Id')?.textContent;
                const sender = transaction.querySelector('Sender')?.textContent;
                const receiver = transaction.querySelector('Destination')?.textContent;
                const amount = transaction.querySelector('Amount')?.textContent;
                const date = transaction.querySelector('FechaOperacion')?.textContent;
                const hora = transaction.querySelector('Data')?.textContent || 'N/A';

                // Formatear la fecha para que solo se muestre la parte de la fecha (YYYY-MM-DD)
                let formattedDate = '';
                if (date) {
                    // Asegurarse de que la fecha esté en el formato correcto antes de extraerla
                    const dateObj = new Date(date);
                    formattedDate = dateObj.toISOString().split('T')[0]; // Extrae solo la parte de la fecha
                }

                content.innerHTML = `
                    <p><strong>Enviado por:</strong> ${sender}</p>
                    <p><strong>Recibido:</strong> ${receiver}</p>
                    <p><strong>Cantidad:</strong> ${amount} €</p>
                    <p><strong>Fecha:</strong> ${formattedDate}</p>
                    <p><strong>Hora:</strong> ${hora}</p>
                `;
            } else {
                content.innerHTML = `<p>No se encontró la última transacción.</p>`;
            }
        } else {
            content.innerHTML = `<p>No se recibió ninguna respuesta del servidor.</p>`;
        }
    });
});
