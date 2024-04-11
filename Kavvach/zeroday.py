from newsapi import NewsApiClient

newsapi = NewsApiClient(api_key="756cca5e9c194af691a07d59262ef1e4")

data = newsapi.get_everything(q='Taylor Swift', language='en', page_size=20)

articles = data['articles']


for (x, y) in enumerate(articles):
    print(f'{x + 1}  {y["title"]}\n')

