from django.http import HttpResponse
from django.template import loader


# Create your views here.
def index(request):
    template = loader.get_template("checkout/index.html")

    return HttpResponse(template.render())
