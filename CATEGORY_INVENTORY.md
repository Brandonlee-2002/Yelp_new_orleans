# New Orleans restaurant category inventory

Source: `data/raw/yelp_academic_dataset_business.json`, read in full. Included businesses have `state == "LA"`, `city == "New Orleans"`, and the exact `Restaurants` token in their comma-separated categories. No open-status or review-count filter was applied.

Found **2,259 restaurants** and **300 distinct comma-separated category tokens**. Counts are numbers of restaurants carrying each token; a restaurant can appear in several categories. Labels preserve the source spelling. The theme groupings below are analytical suggestions, not Yelp hierarchy assignments.

The inference instructions require at least **three related categories**, at least **10 qualifying restaurants**, and coverage of at least **seven geographic areas** under a chosen boundary system. Small categories can contribute to a broader group. None of the categories below has yet been validated against official area boundaries or ranked using reviews. Compare at least two geographic systems before choosing one.

## Categories relevant to dining research

The cuisine, meal, breakfast, and dietary groups provide direct candidate categories. Nightlife labels support a dining-and-drinks theme when restricted to restaurant businesses. Supporting labels are generally better used with specific dining categories.

### Local, American, and European cuisines

| Category | Restaurants |
|---|---:|
| Cajun/Creole | 401 |
| American (New) | 323 |
| American (Traditional) | 299 |
| Southern | 155 |
| Italian | 121 |
| French | 86 |
| Soul Food | 70 |
| Comfort Food | 39 |
| Spanish | 18 |
| Greek | 16 |
| Modern European | 9 |
| Irish | 5 |
| Basque | 3 |
| German | 3 |
| British | 1 |
| Polish | 1 |
| Russian | 1 |
| Ukrainian | 1 |

### Asian cuisines

| Category | Restaurants |
|---|---:|
| Chinese | 69 |
| Vietnamese | 57 |
| Japanese | 54 |
| Asian Fusion | 53 |
| Thai | 25 |
| Indian | 14 |
| Filipino | 7 |
| Korean | 6 |
| Taiwanese | 3 |
| Burmese | 2 |
| Pan Asian | 2 |
| Szechuan | 2 |
| Japanese Curry | 1 |
| Laotian | 1 |
| Malaysian | 1 |
| Shanghainese | 1 |

### Latin American and Caribbean cuisines

| Category | Restaurants |
|---|---:|
| Mexican | 124 |
| Latin American | 51 |
| Caribbean | 34 |
| Tex-Mex | 21 |
| Cuban | 13 |
| Brazilian | 6 |
| New Mexican Cuisine | 6 |
| Peruvian | 5 |
| Venezuelan | 4 |
| Colombian | 3 |
| Honduran | 3 |
| Trinidadian | 3 |
| Haitian | 2 |
| Argentine | 1 |
| Nicaraguan | 1 |
| Salvadoran | 1 |

### Mediterranean, Middle Eastern, African, and Pacific cuisines

| Category | Restaurants |
|---|---:|
| Mediterranean | 58 |
| Middle Eastern | 41 |
| Hawaiian | 9 |
| Lebanese | 9 |
| Turkish | 6 |
| African | 5 |
| Pakistani | 4 |
| Ethiopian | 3 |
| Arabic | 1 |
| Egyptian | 1 |
| Moroccan | 1 |
| Persian/Iranian | 1 |

### Meals, dishes, and restaurant formats

| Category | Restaurants |
|---|---:|
| Sandwiches | 354 |
| Seafood | 331 |
| Burgers | 202 |
| Pizza | 172 |
| Fast Food | 142 |
| Salad | 124 |
| Chicken Wings | 112 |
| Delis | 64 |
| Food Trucks | 62 |
| Barbeque | 61 |
| Sushi Bars | 50 |
| Tapas/Small Plates | 47 |
| Diners | 46 |
| Tacos | 38 |
| Steakhouses | 37 |
| Gastropubs | 31 |
| Soup | 31 |
| Chicken Shop | 25 |
| Hot Dogs | 23 |
| Food Stands | 22 |
| Tapas Bars | 18 |
| Pop-Up Restaurants | 17 |
| Street Vendors | 16 |
| Food Court | 15 |
| Noodles | 15 |
| Ramen | 11 |
| Brasseries | 9 |
| Buffets | 9 |
| Poke | 9 |
| Cheesesteaks | 8 |
| Wraps | 8 |
| Fish & Chips | 7 |
| Cafeteria | 6 |
| Falafel | 6 |
| Dim Sum | 4 |
| Empanadas | 4 |
| Kebab | 4 |
| Delicatessen | 2 |
| Eatertainment | 2 |
| Fondue | 2 |
| Pasta Shops | 2 |
| Smokehouse | 2 |
| Teppanyaki | 2 |
| Themed Cafes | 2 |

### Breakfast, coffee, desserts, and drinks

| Category | Restaurants |
|---|---:|
| Breakfast & Brunch | 367 |
| Coffee & Tea | 208 |
| Cafes | 173 |
| Bakeries | 81 |
| Desserts | 73 |
| Juice Bars & Smoothies | 48 |
| Bagels | 26 |
| Donuts | 26 |
| Ice Cream & Frozen Yogurt | 26 |
| Waffles | 12 |
| Creperies | 11 |
| Coffee Roasteries | 9 |
| Shaved Ice | 7 |
| Bubble Tea | 6 |
| Gelato | 6 |
| Internet Cafes | 6 |
| Patisserie/Cake Shop | 5 |
| Tea Rooms | 5 |
| Candy Stores | 4 |
| Chocolatiers & Shops | 4 |
| Acai Bowls | 3 |
| Custom Cakes | 3 |
| Macarons | 3 |
| Cupcakes | 2 |
| Pretzels | 2 |
| Popcorn Shops | 1 |
| Shaved Snow | 1 |

### Dietary preferences and requirements

| Category | Restaurants |
|---|---:|
| Vegetarian | 70 |
| Vegan | 68 |
| Gluten-Free | 29 |
| Halal | 11 |
| Live/Raw Food | 7 |
| Kosher | 4 |

### Nightlife and drinks as a dining theme

| Category | Restaurants |
|---|---:|
| Nightlife | 540 |
| Bars | 508 |
| Cocktail Bars | 160 |
| Wine Bars | 61 |
| Lounges | 57 |
| Sports Bars | 54 |
| Pubs | 39 |
| Dive Bars | 28 |
| Beer Bar | 16 |
| Breweries | 8 |
| Dance Clubs | 7 |
| Hookah Bars | 7 |
| Beer Gardens | 5 |
| Tiki Bars | 5 |
| Wineries | 5 |
| Champagne Bars | 4 |
| Whiskey Bars | 4 |
| Brewpubs | 3 |
| Gay Bars | 3 |
| Irish Pub | 3 |
| Drive-Thru Bars | 2 |
| Piano Bars | 2 |
| Wine Tasting Room | 2 |
| Cigar Bars | 1 |
| Distilleries | 1 |

### Supporting food, retail, service, and experience labels

| Category | Restaurants |
|---|---:|
| Restaurants | 2259 |
| Food | 725 |
| Specialty Food | 108 |
| Beer | 67 |
| Caterers | 67 |
| Wine & Spirits | 67 |
| Local Flavor | 46 |
| Music Venues | 44 |
| Grocery | 36 |
| Food Delivery Services | 30 |
| Jazz & Blues | 29 |
| Convenience Stores | 25 |
| Seafood Markets | 22 |
| Ethnic Food | 17 |
| Meat Shops | 14 |
| Cheese Shops | 8 |
| Butcher | 7 |
| Fruits & Veggies | 7 |
| Personal Chefs | 6 |
| Farmers Market | 5 |
| Health Markets | 5 |
| Karaoke | 5 |
| Imported Food | 4 |
| Cooking Schools | 3 |
| Do-It-Yourself Food | 3 |
| International Grocery | 2 |
| Organic Stores | 2 |
| Cooking Classes | 1 |
| Ethnic Grocery | 1 |
| Food Tours | 1 |
| Herbs & Spices | 1 |

## Example related category sets

These are starting points, not a ranking of themes. Inclusion means matching at least one listed category. Pair overlap is included to show that the labels occur together; it is not a requirement that all restaurants match every category. Geographic coverage remains unverified.

| Theme | Categories | Unique restaurants | Pair overlaps |
|---|---|---:|---|
| Local New Orleans cooking | Cajun/Creole, Seafood, Southern, Soul Food | 672 | Cajun/Creole + Seafood: 156; Cajun/Creole + Southern: 72; Cajun/Creole + Soul Food: 30; Seafood + Southern: 45; Seafood + Soul Food: 20; Southern + Soul Food: 19 |
| Breakfast and coffee | Breakfast & Brunch, Coffee & Tea, Cafes, Bakeries | 575 | Breakfast & Brunch + Coffee & Tea: 85; Breakfast & Brunch + Cafes: 65; Breakfast & Brunch + Bakeries: 32; Coffee & Tea + Cafes: 75; Coffee & Tea + Bakeries: 37; Cafes + Bakeries: 16 |
| Quick bites | Fast Food, Delis, Donuts | 224 | Fast Food + Delis: 6; Fast Food + Donuts: 0; Delis + Donuts: 2 |
| Desserts and sweets | Desserts, Bakeries, Ice Cream & Frozen Yogurt | 156 | Desserts + Bakeries: 14; Desserts + Ice Cream & Frozen Yogurt: 9; Bakeries + Ice Cream & Frozen Yogurt: 4 |
| Plant-based dining | Vegetarian, Vegan, Salad | 224 | Vegetarian + Vegan: 21; Vegetarian + Salad: 9; Vegan + Salad: 10 |
| East Asian dining | Chinese, Japanese, Korean | 127 | Chinese + Japanese: 2; Chinese + Korean: 0; Japanese + Korean: 0 |
| Mexican and related casual dining | Mexican, Tacos, Tex-Mex | 127 | Mexican + Tacos: 38; Mexican + Tex-Mex: 18; Tacos + Tex-Mex: 9 |

## Other labels attached to restaurant records

These incidental labels are retained for completeness, but do not directly define a restaurant cuisine or meal category.

| Category | Restaurants |
|---|---:|
| Event Planning & Services | 156 |
| Arts & Entertainment | 86 |
| Venues & Event Spaces | 63 |
| Hotels & Travel | 38 |
| Shopping | 38 |
| Hotels | 29 |
| Party & Event Planning | 20 |
| Active Life | 13 |
| Tours | 6 |
| Festivals | 5 |
| Art Galleries | 5 |
| Arcades | 4 |
| Pool Halls | 4 |
| Automotive | 4 |
| Gas Stations | 4 |
| Wedding Planning | 4 |
| Specialty Schools | 4 |
| Education | 4 |
| Local Services | 3 |
| Health & Medical | 3 |
| Flowers & Gifts | 3 |
| Boat Charters | 3 |
| Pop-up Shops | 3 |
| Fitness & Instruction | 3 |
| Home & Garden | 3 |
| Home Services | 3 |
| Tobacco Shops | 3 |
| Wholesale Stores | 3 |
| Beauty & Spas | 2 |
| Adult Entertainment | 2 |
| Bowling | 2 |
| Herbal Shops | 2 |
| Mags | 2 |
| Bookstores | 2 |
| Books | 2 |
| Arts & Crafts | 2 |
| Music & Video | 2 |
| Golf | 2 |
| Sporting Goods | 2 |
| Souvenir Shops | 2 |
| Gift Shops | 2 |
| Resorts | 2 |
| Musicians | 2 |
| Performing Arts | 2 |
| Swimming Pools | 2 |
| Travel Services | 2 |
| Parks | 2 |
| Gyms | 2 |
| Public Services & Government | 2 |
| Landmarks & Historical Buildings | 2 |
| Real Estate | 2 |
| Shopping Centers | 2 |
| Bed & Breakfast | 1 |
| Religious Organizations | 1 |
| Hair Salons | 1 |
| Skin Care | 1 |
| Day Spas | 1 |
| Vitamins & Supplements | 1 |
| Electronics Repair | 1 |
| Barbers | 1 |
| Nutritionists | 1 |
| Drugstores | 1 |
| Cards & Stationery | 1 |
| Community Service/Non-Profit | 1 |
| Boating | 1 |
| Boat Tours | 1 |
| Kids Activities | 1 |
| Indoor Playcentre | 1 |
| Mass Media | 1 |
| Golf Lessons | 1 |
| Golf Equipment | 1 |
| Kitchen & Bath | 1 |
| Vape Shops | 1 |
| Holiday Decorations | 1 |
| Tree Services | 1 |
| Home Decor | 1 |
| Christmas Trees | 1 |
| Yelp Events | 1 |
| Adult | 1 |
| Cabaret | 1 |
| Bike Repair/Maintenance | 1 |
| Bikes | 1 |
| Professional Services | 1 |
| Sports Wear | 1 |
| Fashion | 1 |
| Personal Shopping | 1 |
| Travel Agents | 1 |
| Aquariums | 1 |
| Discount Store | 1 |
| Photographers | 1 |
| Social Clubs | 1 |
| Country Clubs | 1 |
| Supernatural Readings | 1 |
| Auction Houses | 1 |
| Cultural Center | 1 |
| Walking Tours | 1 |
| Historical Tours | 1 |
| Art Tours | 1 |
| Tabletop Games | 1 |
| Apartments | 1 |
| Party Supplies | 1 |
| Bar Crawl | 1 |
| Nurseries & Gardening | 1 |
| Real Estate Agents | 1 |
| Shared Office Spaces | 1 |

**Parsing note:** The assignment treats commas as category separators. Consequently, `Beer` and `Wine & Spirits`, and `Books`, `Mags`, `Music & Video`, appear as separate tokens. Do not infer that each token is necessarily a separate canonical Yelp category.
