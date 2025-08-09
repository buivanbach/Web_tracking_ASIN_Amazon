# Centralized locators and parsing config for Amazon product pages

TITLE = '#productTitle'
PRICE_PRIMARY = 'span.a-price span.a-offscreen'
PRICE_FALLBACK = 'span.a-price-whole'
BRAND = '#bylineInfo'
RATINGS = '#acrCustomerReviewText'
STARS = 'span.a-icon-alt'
IMAGE_WRAPPER_IMG = "#imgTagWrapperId img"
DETAIL_BULLETS_ITEMS = '#detailBulletsWrapper_feature_div li'
DETAILS_TABLE_ROWS = '#prodDetails table tr'

# Captcha detection keywords
CAPTCHA_KEYWORDS = [
    'captchacharacters',
    '/captcha/',
    'enter the characters',
    "we just need to make sure you're not a robot",
    'not a robot',
    'automated access to amazon data',
    'type the characters',
    'sorry there was a problem with your request',
    'continue shopping',
    'click the button below to continue shopping',
]


