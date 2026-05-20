---
layout: page
title: Concerts
image:
  path: /images/photos/old-photo.jpg
---

{% assign sorted = site.concerts | sort: 'date' %}
{% assign upcoming = sorted | where_exp: 'c', 'c.date >= site.time' %}
{% assign past = sorted | where_exp: 'c', 'c.date < site.time' | reverse %}

{% assign next_concert = upcoming | first %}
{% assign most_recent_past_season = past[0].season %}
{% assign most_recent_past = past | where: 'season', most_recent_past_season %}

## Next Concert

{% if next_concert %}
### [{{ next_concert.title }}]({{ next_concert.url }})

{% include concert-full.html concert=next_concert %}
{% else %}
_No upcoming concerts scheduled. Check back soon._
{% endif %}

## Upcoming Concerts

{% if upcoming.size > 1 %}
{% for c in upcoming offset:1 %}
### [{{ c.title }}]({{ c.url }})

{% include concert-full.html concert=c %}
{% endfor %}
{% else %}
_No additional upcoming concerts at this time._
{% endif %}

## Past Concerts

### [{{ most_recent_past_season }} Season](/concerts/season/{{ most_recent_past_season }}/)

<ul class="concert-cards">
{% for c in most_recent_past %}{% include concert-card.html concert=c %}{% endfor %}
</ul>

#### Other Seasons

<ul>
{% for s in site.data.seasons.seasons %}{% unless s.id == most_recent_past_season %}<li><a href="/concerts/season/{{ s.id }}/">{{ s.label }}</a></li>
{% endunless %}{% endfor %}</ul>
