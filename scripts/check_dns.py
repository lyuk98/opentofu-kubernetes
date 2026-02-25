#!/usr/bin/env python3

"""
This script continuously checks provided domain's A and AAAA records until they match provided IPv4
and IPv6 addresses or when the timeout is reached. It can be used to wait for DNS propagation.

The following environment variables are accessed:

- ADDRESS: the domain to check DNS records against
- DNS_RECORDS_A: JSON-formatted data representing a list of expected IPv4 addresses
- DNS_RECORDS_AAAA: JSON-formatted data representing a list of expected IPv6 addresses
- INTERVAL: interval between DNS queries in seconds; defaults to 10
- TIMEOUT: timeout for the process in seconds; defaults to 300
"""

import concurrent.futures
import json
import os
import socket
import sys
import time


def getaddrinfo(domain: str):
    """Returns IPv4 and IPv6 addresses for the given domain"""

    # Sets are used since duplicate values may exist
    ipv4 = set()
    ipv6 = set()

    for family, _, _, _, sockaddr in socket.getaddrinfo(domain, None):
        address = sockaddr[0]

        if family == socket.AF_INET:
            ipv4.add(address)
        elif family == socket.AF_INET6:
            ipv6.add(address)

    return (ipv4, ipv6)


def check_dns(domain, ipv4_addresses, ipv6_addresses, timeout):
    """Checks if the domain's records match expected ones"""

    with concurrent.futures.ThreadPoolExecutor() as executor:
        future = executor.submit(getaddrinfo, domain)

        try:
            (ipv4, ipv6) = future.result(timeout=timeout)

            if ipv4 == ipv4_addresses and ipv6 == ipv6_addresses:
                print("DNS records match", file=sys.stderr)
                return True

            print("DNS records do not match", file=sys.stderr)

        except concurrent.futures.TimeoutError:
            print("Name resolution timed out", file=sys.stderr)
        except Exception as exception:  # pylint: disable=broad-exception-caught
            print(f"Name resolution failure: {exception}", file=sys.stderr)

    return False


# Set data from environment variables
check_domain = os.environ["ADDRESS"]
dns_records_a = set(json.loads(os.environ["DNS_RECORDS_A"]))
dns_records_aaaa = set(json.loads(os.environ["DNS_RECORDS_AAAA"]))
interval = int(os.environ.get("INTERVAL", "10"))
validation_timeout = time.time() + int(os.environ.get("TIMEOUT", "300"))

while True:
    # Check DNS records and exit if they match
    if check_dns(check_domain, dns_records_a, dns_records_aaaa, interval):
        sys.exit(0)

    # Abort if timeout is reached
    if time.time() >= validation_timeout:
        break

    time.sleep(interval)

sys.exit(1)
