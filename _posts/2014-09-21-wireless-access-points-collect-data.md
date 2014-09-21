---
title: Wireless Access Points Collect Data
layout: post
---
Wireless Access Points Collect Data
===================================
Through some coincidences today, I realized a scary reality of wireless access
points (WAPs). WAPs are operating systems. As such, the people controlling them
have a lot of power. They like that power, and they tend do what web companies
do; collect massive amounts of data.

When your wireless devices try to *discover* the local wifi networks available
(not even connect), they send out what's called a probe request. Probe requests
contain your device's MAC address. MAC addresses are, generally, unique to each
hardware device; so they can be linked back to you fairly easily. The scary
thing, is that WAPs can, and do, collect this information and send it back to
a central location to be logged.

Without even connecting to a Wi-Fi network (granted your Wi-Fi is on), WAPs (and
the people behind the WAPs) can tell where you are at any given time.

Apple has recently made a slight improvement to your security in their latest
release of iOS8. In iOS8, the MAC address is randomized in probe requests. This
helps mask your identity when searching for networks.

Unfortunately, even if your MAC is randomized in probe requests, WAPs can still
track that they received the request. And with [Wi-Fi positioning
systems](http://en.wikipedia.org/wiki/Wi-Fi_positioning_system), it's not
inconceivable that WAPs can tie together someone's whereabouts even if they
never connect.

Even if you have iOS8, you're nowhere close to being anonymous. As far as I can
tell, iOS8 still uses your device's real MAC address when it is actually
interacting with a Wi-Fi network.

MAC addresses are sent unencrypted to WAPs; even if the Wi-Fi network is using
encryption! Other WAPs in the vicinity could potentially sniff out MAC
addresses on other networks and log the information.

Despite the positive conversation around this tweet suggesting that iOS8 has
fixed the problem once and for all:

<blockquote class="twitter-tweet" lang="en"><p><a href="https://twitter.com/jmarcelino">@jmarcelino</a> yep, Session 715. They&#39;re super strict with identifier usage and you need to explain why when submitting. <a href="http://t.co/OaHJyUJyRe">pic.twitter.com/OaHJyUJyRe</a></p>&mdash; Luis Abreu (@lmjabreu) <a href="https://twitter.com/lmjabreu/status/475594066907111424">June 8, 2014</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

The problem is still there. Here is the representation of a MAC frame:

    |------------------------------------------------------|
    | MAC header | Frame Body | Frame Check Sequence (FCS) |
    |------------------------------------------------------|

The MAC header includes both the source and desination MAC addresses. And just
to be sure, the MAC specification 802.15.3-2003 Section 7.3.4.2 (Secure data
frame) states that "If the symmetric key security operations in use requires
data encryption, the Data Payload field shall be encrypted". It speaks nothing
of encrypting the MAC header. [See this microsoft post for more
detail](http://technet.microsoft.com/en-us/library/cc757419(v=ws.10).aspx).

The last scary detail is that only a handful of companies run wireless access
points. Some companies are collecting a lot of data from a lot of places.
