document.addEventListener("DOMContentLoaded", function () {
    // Obtener el nombre de usuario desde sessionStorage
    const username = sessionStorage.getItem('login_username');
    const ssid = sessionStorage.getItem('ssid');

    // Verificar que el nombre de usuario esté presente
    if (!username) {
        alert("No se ha iniciado sesión.");
        return;
    }

    // Construir la URL para la llamada AJAX
    const url = `http://ws.mybizum.com:8080/ws.php?action=get_transactions&ssid=${encodeURIComponent(ssid)}`;

    // Crear una instancia de clsAjax
    const ajax = new clsAjax(url, null);
    ajax.Call();

    // Escuchar el evento personalizado disparado por clsAjax cuando se recibe la respuesta
    document.addEventListener("_CALL_RETURNED_", function () {
        const response = ajax.xml.trim();

        console.log("Respuesta del servidor:", response);

        if (response) {
            // Parsear la respuesta XML
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(response, "text/xml");

            // Verificar si hay un error en la respuesta
            const error = xmlDoc.querySelector('Error');
            if (error) {
                alert("Error en el servidor: " + error.textContent);
                return;
            }

            // Limpiar la tabla antes de agregar las transacciones
            const tableBody = document.querySelector('#transactionsTable tbody');
            tableBody.innerHTML = '';

            // Recorrer el XML y agregar las filas a la tabla
            const transactions = xmlDoc.getElementsByTagName('Transaction');
            for (let i = 0; i < transactions.length; i++) {
                const transaction = transactions[i];

                const id = transaction.querySelector('Id').textContent;
                const sender = transaction.querySelector('Sender').textContent;
                const receiver = transaction.querySelector('Destination').textContent;
                const amount = transaction.querySelector('Amount').textContent;
                const date = transaction.querySelector('FechaOperacion').textContent;
                const hora = transaction.querySelector('Data').textContent;
                const time = transaction.querySelector('HoraOperacion') ? transaction.querySelector('HoraOperacion').textContent : 'N/A';

                // Formatear la fecha para que solo se muestre la parte de la fecha (YYYY-MM-DD)
                let formattedDate = '';
                if (date) {
                    // Asegurarse de que la fecha esté en el formato correcto antes de extraerla
                    const dateObj = new Date(date);
                    formattedDate = dateObj.toISOString().split('T')[0]; // Extrae solo la parte de la fecha
                }

                let rowClass = '';
                if (sender === username) {
                    rowClass = 'sender-you';
                } else if (receiver === username) {
                    rowClass = 'receiver-you';
                }

                tableBody.innerHTML += `
                    <tr class="${rowClass}">
                        <td>${id}</td>
                        <td>${sender}</td>
                        <td>${receiver}</td>
                        <td>${amount} €</td>
                        <td>${formattedDate}</td> 
                        <td>${hora}</td>
                    </tr>
                `;
            }
        } else {
            alert("No se encontraron transacciones.");
        }
    });
});
