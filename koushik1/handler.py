import requests

url = "http://localhost:8080/function/koushik1"

data = {
    "a": 10,
    "b": 20
}

response = requests.post(url, json=data)

print(response.json())