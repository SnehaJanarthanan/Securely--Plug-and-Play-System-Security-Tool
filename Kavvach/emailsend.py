import random
import string
import ssl
import smtplib
from email.message import EmailMessage
import string
import ssl
import smtplib
from email.message import EmailMessage

def generate_otp(length=6):
    characters = string.digits
    return ''.join(random.choice(characters) for _ in range(length))

sender = 'securelyskcet@gmail.com'
password = 'mcfudxxexrcmevua'
receiver = '727721eucs146@skcet.ac.in'

subject = 'Your OTP for verification'
otp = generate_otp()
body = f"Your OTP is: {otp}"

em = EmailMessage()
em['From'] = sender
em['To'] = receiver
em['Subject'] = subject
em.set_content(body)

context = ssl.create_default_context()

with smtplib.SMTP_SSL('smtp.gmail.com', 465, context=context) as smtp:
    smtp.login(sender, password)
    smtp.sendmail(sender, receiver, em.as_string())
