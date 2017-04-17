#!/usr/bin/python
# Subdomain discovery via Threatcrowd, Assetnote Probe
# Author: shubs

import requests
import sys
import time
import sqlite3
import os
from pushover import init, Client
from datetime import datetime

sys.path.append(
    os.path.abspath(os.path.join(os.path.dirname(__file__), os.path.pardir)))

import config

init(config.PUSHNOTIFY_KEY)

# Initiate manager
BASE_DIR = os.path.join( os.path.dirname( __file__ ), '..' )
DATABASE = BASE_DIR+ '/assetnote.db'
conn = sqlite3.connect(DATABASE)
c = conn.cursor()
c.execute("select * from domains")
all_domains_to_scan = c.fetchall()

def grab_subdomains_for_domain(domain):
    api_url = "http://www.threatcrowd.org/searchApi/v2/domain/report/?domain={0}".format(domain)
    try:
        api_call = requests.get(api_url)
    except ConnectionError as e:
        print("[-] Could not connect to {}, error: {}".format(api_url, str(e)))
    except Exception as e:
        print("[-] Something went wrong when connecting to {}, error: {}".format(api_url, str(e)))
    else:
        if api_call.status_code == 200:
            print(api_call.content)
            api_results = api_call.json()
            return api_results['subdomains']
        else:
             print("[-] {} returned HTTP {}".format(api_url, api_call.status_code))

def check_if_known_in_db(subdomain, pushover_key):
    c.execute("select new_domain from sent_notifications where push_notification_key = ?", (pushover_key,))
    already_sent = c.fetchall()
    should_i_send = True
    try:
        for known_sub in already_sent:
            if known_sub[0] == subdomain:
                should_i_send = False
                print("[*] Already known domain found: {0}".format(subdomain))
    except Exception as e:
        print("No domains found in assenote DB - results found will not be sent")
        should_i_send = False
    return should_i_send

def send_notification(subdomain, pushover_key, first_run):
    if first_run == "Y":
        c.execute("insert into sent_notifications(new_domain, push_notification_key, time_sent) values(?, ?, ?)", (subdomain, pushover_key, datetime.now()))
        conn.commit()
        print("[*] First run: {0}".format(subdomain))
    elif first_run == "N":
        Client(pushover_key).send_message("New domain found: {0}".format(subdomain), title="Threatcrowd Notify")
        c.execute("insert into sent_notifications(new_domain, push_notification_key, time_sent) values(?, ?, ?)", (subdomain, pushover_key, datetime.now()))
        conn.commit()

for domain in all_domains_to_scan:
    target = domain[1]
    first_run = domain[2]
    push_key = domain[3]
    domain_id = domain[0]
    subdomains_found = grab_subdomains_for_domain(target)
    if subdomains_found:
        try:
            for subdomain in subdomains_found:
                if check_if_known_in_db(subdomain, push_key) == True:
                    send_notification(subdomain, push_key, first_run)
                    if first_run == "Y":
                        c.execute("UPDATE domains SET first_scan = 'N' WHERE d_id = ?", (domain_id,))
                        conn.commit()
                else:
                    pass
            print("[*] Completed proccess for {0}".format(domain))
        except Exception as e:
            print("[*] Failed: {0}".format(str(e)))
    else:
        print("[*] No subdomains found...")

