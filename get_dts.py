#!/usr/bin/python3
#**************************************************************************
#   Filename:           rn_prep.py
#   Author:             Robert Hillen           
#   Created:            June 1, 2019
#   Description:        
#
#
#**************************************************************************
#              Copyright (c) 2019 Nokia
#**************************************************************************
import re, string, sys
import requests
import datetime
from bs4 import BeautifulSoup, NavigableString
import warnings
from rn_prep_input import *
warnings.filterwarnings("ignore")

try:
    with open("user.txt") as f:
        username = f.readline().strip()
        password = f.readline().strip()

except FileNotFoundError:
    username = input("Enter DTS username: ")
    password = input("Enter DTS password: ")
    print("Save user/password to disk file user.txt?")
    print("!!!WARNING: password will be saved in clear text!!!")
    save = input('[y/N]')
    if save.lower()[0] == 'y':
        f = open("user.txt", 'w')
        f.write("%s\n" % username)
        f.write("%s\n" % password)
        f.close()

def combine_rel(major, minor):
    major = re.search(r'(\d+\.\d+).*', major)[1]
    m = re.search(r'^[0-9\.]*(([ISRBFisrb])?\d+(-\d+)?)$', minor)
    if m is None:
        return(major)
    if m.group(2) == "":
        minor = ".R" + m.group(1)
    else:
        minor = "." + m.group(1)
    return(major + minor)

def urls(report_detail):
    major2subid = {
        "15.0": "127",
        "16.0": "144",
        "19.5": "152",
    }

    url_dict = { 
        "res_rn_issues": "https://dts.mv.usa.alcatel.com/dts/cgi-bin/query.cgi?action=search;build_fixed=" + \
            minor + ";release_note_flag=1;reportDetail=" + report_detail + ";report_type=0;subreport_id=" + major2subid[major],
        "res_cust_issues": "https://dts.mv.usa.alcatel.com/dts/cgi-bin/query.cgi?action=search;build_fixed=" + \
            minor + ";customer_id=any;reportDetail=" + report_detail + ";report_type=0;subreport_id=" + major2subid[major],
        "kn_rn_issues": "https://dts.mv.usa.alcatel.com/dts/cgi-bin/query.cgi?action=search;release_note_flag_date_from=" + \
            last_build + ";release_note_flag=1;reportDetail=" + report_detail + ";report_type=0;subreport_id=" + major2subid[major],
        "kn_cust_issues": "https://dts.mv.usa.alcatel.com/dts/cgi-bin/query.cgi?action=search;modified_date_from=" + \
            last_build + ";customer_id=any;reportDetail=" + report_detail + ";report_type=0;subreport_id=" + major2subid[major],
        }    
    return(url_dict)

def xlate_dts_text(inp_str):
    output = re.sub(r'[\x92]',r"'", inp_str)
    output = re.sub(r'[\x93-\x94]',r'"', output)
    output = re.sub(r'(\[\S.*?\S)\]',r'\1\\]', output)
    return(output)

def parse_dts():
    login_url = "https://sso.mv.usa.alcatel.com/login.cgi"
    payload = {
            "username": username, 
            "password": password, 
    }
    s = requests.session()
    r1 = s.post(
            login_url, 
            data = payload, 
            verify = False,
            headers = dict(referer=login_url)
    )
    #print(r1.text)
    dts_s = {}
    for query, url in urls("customer_detail").items():
        r = s.get(
                url, 
                headers = dict(referer = url),
                verify = False,
                cookies=r1.cookies
        )
        page = BeautifulSoup(r.text, features="lxml")
        table = page.find('table', id="subreport_list")
        #print(list(table.children))
        rows = table.find_all("tr")
        dts = ""
        for row in rows:
            dts_struct = {}
            rn = row.find('fieldset')
            if rn is None:
                cols = row.find_all('td')
                cols = [ele.text.strip() for ele in cols]
                if len(cols) == 0: continue
                # print(cols)
                dts = re.search(r'(\d+)-', cols[1])[1]
                if dts in dts_s.keys(): continue
                dts_struct['type'] = cols[0]
                dts_struct['sev'] = cols[3]
                dts_struct['state'] = cols[4]
                dts_struct['added'] = cols[5]
                dts_struct['origin'] = cols[8]
                dts_struct['rn_flag'] = cols[9]
                dts_struct['4ls'] = cols[10]
                dts_struct['title'] = xlate_dts_text(cols[11])
                dts_struct['found_in'] = combine_rel(cols[13], cols[14])
                dts_struct['rn'] = None
                dts_s[dts] = dts_struct.copy()
            else:
                rn_wo = rn.get_text()[14:]
                dts_s[dts]['rn'] = xlate_dts_text(rn_wo)
                #print(dts, ":", hex_escape(rn_wo)
        
            #print("++++++++++++++++++++++++++++")
    for query, url in urls("csv").items():
        r = s.get(
                url, 
                headers = dict(referer = url),
                verify = False,
                cookies=r1.cookies
        )
        page = BeautifulSoup(r.text, features="lxml")
        table = page.find('table', id="subreport_list")
        #print(list(table.children))
        csv = list(table.find_all("td")[0].stripped_strings)
        for row in csv:
            cols = row.split(",")
            dts = cols[0]
            if dts not in dts_s.keys(): continue
            dts_s[dts]['fixed'] = cols[15]
            dts_s[dts]['customer'] = cols[19]
    return(dts_s)

def hex_escape(s):
    printable = string.ascii_letters + string.digits + string.punctuation + ' ' + '\n'
    return ''.join('' if c in printable else r'\x{0:02x}'.format(ord(c)) for c in s)

def dts_link(dts):
    return("[%s|https://dts.mv.usa.alcatel.com/dts/cgi-bin/viewReport.cgi?report_id=%s;subreport_id=%s#part2]" % \
                 (dts, dts, subreport))

def get_dts_fix_rel(dts):
    minor = re.search(r'(R\d+(-\d+)?)', dts_s[dts]["fixed"])
    if minor is not None:
        dts_fix_rel = major + "." + minor[0]
        return(dts_fix_rel)
    else:
        return(None)

def print_dts_h(dts):
    if dts_s[dts]["4ls"] == "":
        orig_4ls = "origin: %s" % dts_s[dts]["origin"]
    else:
        orig_4ls = "4ls: %s" % dts_s[dts]["4ls"]
    fixed_str = ""
    if is_fixed(dts):
        fixed_str = " fixed in: %s," % get_dts_fix_rel(dts)
    print("h4. %s %s: State: %s,%s %s - %s" % (dts_s[dts]["type"], dts_link(dts), dts_s[dts]["state"], fixed_str, \
          orig_4ls, dts_s[dts]["title"]))

def print_dts_rn(dts_list):
    severity = {
        "S0": "CR",
        "S1": "MA",
        "S2": "MA",
        "S3": "MI",
        "S4": "MI",
    }
    for dts in dts_list:
        print_dts_h(dts)
        if dts_s[dts]["rn"]:
            wu = dts_s[dts]["rn"]
            wu_dts = re.search('\[\d{5,6}\-(MA|MI|CR)\]', wu)
            if not wu_dts:
                wu = wu + '[' + dts + '-' + severity[dts_s[dts]["sev"]] + '\]'
            print(wu)
            print()

def print_rn_wu(dts, text, wu):
    fixed_str = ""
    if is_fixed(dts):
        fixed_str = "fixed in: %s " % get_dts_fix_rel(dts)
    print("h4. %s %s: State: %s, %s- %s" % (dts_s[dts]["type"], dts_link(dts), dts_s[dts]["state"], fixed_str, text))
    print(wu)

def is_fixed(dts):
    return(dts_s[dts]["state"] == "Fix Sub" or dts_s[dts]["state"][:16] == "Closed: Verified") or \
        (get_dts_fix_rel(dts) is not None and dts_s[dts]["state"][:21] == "Closed: Branch closed")

def print_text(dts, index, prev_release, res_rel, comp, wu):
    if res_rel is not None:
        text = "copy from %s RNs resolved issues section *%s - %s*" % (prev_release, res_rel.strip(), comp.strip())
    else:
        text = "copy from %s RNs known issues section *%s*" % (prev_release, comp.strip())
    print_rn_wu(dts, text, wu)

def rel2major_minor(release):
    m = re.search('^(\d+\.\d+)\.(R.*)$',release)
    if not m:
        print("Invalid target release: %s")
        sys.exit()
    major = m.group(1)
    minor = m.group(2)
    return(major, minor)

dts_fixed_rn = []
dts_fixed_cust_no_rn = []
dts_known_rn = []
dts_known_cust_no_rn = []

head_data = [{
    "h1":   "h1. Resolved issue DTS's - RN flag set",
    "h2_1": "h2. DTS's found in other RN sections",
    "h2_2": "h2. To be added in %s RNs resolved issues from DTS" % (target_release),
    "dts_s": dts_fixed_rn}, {
    "h1":   "h1. Resolved customer issue DTS's - RN flag not set",
    "h2_1": "h2. DTS's found in other RN sections",
    "h2_2": "h2. DTS's to be reviewed for inclusion in RN's resolved issues",
    "dts_s": dts_fixed_cust_no_rn}, {
    "h1":   "h1. Known issue DTS's with RN flag set after last release build date",
    "h2_1": "h2. DTS's found in other RN sections",
    "h2_2": "h2. DTS's to be reviewed for inclusion in RN's known issues",
    "dts_s": dts_known_rn}, {
    "h1":   "h1. Known customer issue DTS's modified after last release build date - RN flag not set",
    "h2_1": "h2. DTS's found in other RN sections",
    "h2_2": "h2. DTS's to be reviewed for inclusion in RN's known issues",
    "dts_s": dts_known_cust_no_rn},
]

no_exist = [
    "Closed: No plan to fix",
    "Closed: No plan to fi",
    "Closed: Erroneous",
    "Closed: Rejected"]

major, minor = rel2major_minor(target_release)
subreport = re.sub(r'(\d+)\.(\d+)',r'\1\2B', major)
dts_s = parse_dts()
reject_dts_s = []
reject_areas = [x.lower() for x in reject_areas]
for dts in sorted(dts_s.keys()):
    remove_dts = False
    for state in no_exist:
        if dts_s[dts]["state"] == state:
            reject_dts_s.append([dts, "state = %s" % state])
            remove_dts = True
            break
    if remove_dts: continue
    fixed = is_fixed(dts)
    action = ""
    skip = False
    if dts_s[dts]["rn"]:
        lines = dts_s[dts]["rn"].splitlines()
        action = lines[0][:4]
        # print(dts, lines)
        for line in lines:
            if line[:4].lower() == "dnrn":
                reject_dts_s.append([dts, "action = " + line])
                skip = True
                break
            if line[:4].lower() == "rnwf" and not fixed:
                reject_dts_s.append([dts, "action = " + line])
                skip = True
                break
            if line.lower() in reject_areas:
                reject_dts_s.append([dts, "area = " + line])
                skip = True
                break
    if skip: continue
    rn_flag = dts_s[dts]["rn_flag"] == "RN"
    cust = dts_s[dts]["customer"] != ""
    if fixed and rn_flag:
        dts_fixed_rn.append(dts)
    elif fixed and not rn_flag and cust:
        dts_fixed_cust_no_rn.append(dts)
    elif not fixed and rn_flag:
        dts_known_rn.append(dts)
    elif not fixed and not rn_flag and cust:
        dts_known_cust_no_rn.append(dts)
    #print(dts, fixed, rn_flag, cust, dts_s[dts]["state"][:6])

rn_res_dat = []
for filen in rn_resolved:
    rn_res_dat.append(get_resolved(filen))
rn_known_dat = []
for filen in rn_known:
    rn_known_dat.append(get_known(filen))

with open("rn_prep_output.txt", "w") as f:
    stdout = sys.stdout
    sys.stdout = f
    now = datetime.datetime.now()
    print("Last updated by rn_prep.py script on %s" % now.strftime("%Y-%m-%d %H:%M"))
    for index, head_item in enumerate(head_data):      
        print(head_item["h1"])
        print(head_item["h2_1"])
        rn_cand = []
        for dts in head_item["dts_s"]:
            dts_fix_rel = get_dts_fix_rel(dts)
            skip = False
            found_rn_rel = None
            for i, rel in enumerate(prev_releases):
                if dts in rn_res_dat[i].keys():
                    res_rel =  rn_res_dat[i][dts]["rel"]
                    if dts_fix_rel ==  res_rel:
                        reject_dts_s.append([dts, "Already in RN %s resolved issues" % res_rel])
                        skip = True
                        break
                    if res_rel in skip_prev_resolved_rel:
                        reject_dts_s.append([dts, "Already in previous RN %s resolved issues" % res_rel])
                        skip = True
                        break
                    if not found_rn_rel:
                        found_rn_rel = rel
                        dts_res_rel = res_rel
                        wu =  rn_res_dat[i][dts]["wu"]
                        comp =  rn_res_dat[i][dts]["comp"]
                elif dts in rn_known_dat[i].keys():
                    res_rel =  None
                    if rel2major_minor(rel)[0] == major and not is_fixed(dts):
                        reject_dts_s.append([dts, "Already in RN %s known issues" % rel])
                        skip = True
                        break
                    if not found_rn_rel:
                        found_rn_rel = rel
                        dts_res_rel = res_rel
                        wu =  rn_known_dat[i][dts]["wu"]
                        comp =  rn_known_dat[i][dts]["comp"]
            if found_rn_rel and not skip:
                print_text(dts, index, found_rn_rel, dts_res_rel, comp, wu)
            elif not skip:
                rn_cand.append(dts)
        print(head_item["h2_2"])
        print_dts_rn(rn_cand) 
    #sys.stdout = stdout
    print("h1. Skipped DTS's") 
    for dts in reject_dts_s:
        print("%s: %s" % (dts_link(dts[0]), dts[1])) 
