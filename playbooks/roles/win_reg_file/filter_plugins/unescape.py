#!/usr/bin/python
from ansible.errors import AnsibleFilterError
def filter_unescape(val):
    if isinstance(val, str):
        return val.encode('utf-8').decode('unicode_escape')
    else:
        raise AnsibleFilterError("Given input is not instance of str")

class FilterModule(object):
    filter_map = {
        'unescape': filter_unescape
    }

    def filters(self):
        return self.filter_map