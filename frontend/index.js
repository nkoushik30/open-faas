const fetch = require("node-fetch");

async function test() {
    const res = await fetch("http://localhost:8080/function/koushik1", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({ a: 5, b: 4 })
    });

    const data = await res.json();
    console.log(data);
}

test();