---
layout: page
title: Dundas Valley Orchestra
description: "Dundas Valley Orchestra is an amateur orchestra in Hamilton, Ontario"
image:
  path: /images/photos/2024-25 group picture cropped.jpeg
---

## Next Concert

{% assign sorted = site.concerts | sort: 'date' %}
{% assign upcoming = sorted | where_exp: 'c', 'c.date >= site.time' %}
{% assign next_concert = upcoming | first %}
{% if next_concert %}
### [{{ next_concert.title }}]({{ next_concert.url }})
{% include concert-full.html concert=next_concert %}
{% else %}
_No upcoming concerts scheduled. Check back soon._
{% endif %}

[More concert information →](/concerts){: .btn .btn--accent}

***

[Donate now](http://www.canadahelps.org/CharityProfilePage.aspx?BN=118889476RR0001){: .btn .btn--success .btn--block .btn--large}

***

# Last concert video

### Last concert

Full livestream:

<div style="padding:56.25% 0 0 0;position:relative;">
    <iframe src="https://player.vimeo.com/video/1197135179" frameborder="0" allow="autoplay; fullscreen; picture-in-picture; clipboard-write; encrypted-media" style="position:absolute;top:0;left:0;width:100%;height:100%;" title="The DVO plays Mahler! – Sunday, May 31, 2026" data-ready="true"></iframe>
  </div>

***

# DVO on social media

[Facebook page](https://www.facebook.com/DundasValleyOrchestra){: .btn .btn--info} [Instagram feed](https://www.instagram.com/dundasvalleyorchestra/){: .btn .btn--info} [Youtube channel](https://www.youtube.com/@dundasvalleyorchestra4839){: .btn .btn--info}

Note that the Youtube channel has some of our concerts and clips. Many of our concerts are on Vimeo, accessed through this website.

***

# Student musician programs

* Glenn Mallory Scholarship
* DVO-HAALSA Young Musician Award
* DVO Student Composer Competition

[More information about the student programs →](/students/){: .btn .btn--accent}

***

# Dundas Valley Orchestra

[Laura M. Thomas, B.Mus., M.F.A., Music Director](/about/#conductor)

The Dundas Valley Orchestra provides amateur musicians the opportunity and joy of performing orchestral music. Musicians of all ages improve their skills and share this talent by performing community concerts and free concerts at community institutions such as nursing and retirement homes.

[More information about the orchestra →](/about){: .btn .btn--accent}

<hr>

## Partners

<img src="/images/supporters/Orchestras-Canada-logo.jpg" alt="Orchestras Canada" width="40%" border="0">

A member of <a href="https://oc.ca/">Orchestras Canada</a>

## Financial Supporters

|  |  |
|:-:|:-:|
| <img src="/images/supporters/Trillium-logo.jpg" alt="Ontario Trillium Foundation" width="40%" border="0"> | <img src="/images/supporters/Hamilton-logo.jpg" alt="The City of Hamilton" width="40%" border="0"> |
| <a href="http://www.otf.ca/">Ontario Trillium Foundation</a> | <a href="https://www.hamilton.ca">The City of Hamilton</a> |
| <img src="/images/supporters/OAC-logo.gif" alt="Ontario Arts Council" width="40%" border="0"> | <img src="/images/supporters/HCF-logo.png" alt="Hamilton Community Foundation" width="50%" border="0"> |
| <a href="http://www.arts.on.ca">Ontario Arts Council</a> | <a href="https://www.hamiltoncommunityfoundation.ca">Hamilton Community Foundation</a> |
| <img src="/images/supporters/haalsa.png" alt="Hamilton Association for the Advancement of Literature, Science and Art" width="40%" border="0"> | <img src="/images/supporters/incite-logo.png" alt="incite Foundation for the Arts" width="40%" border="0"> |
| <a href="http://www.haalsa.org">Hamilton Association for the Advancement of Literature, Science and Art</a> | <a href="https://incitefoundation.ca">incite Foundation for the Arts</a> |
