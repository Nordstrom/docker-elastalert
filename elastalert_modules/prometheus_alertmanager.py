import simplejson
import logging
import warnings
#import pprint
import requests
from elastalert.alerts import Alerter, BasicMatchString
from elastalert.util import elastalert_logger
from elastalert.util import EAException
from datetime import datetime
from requests.exceptions import RequestException

class PrometheusAlertManagerAlerter(Alerter):
  required_options = frozenset(['alertmanager_url'])

  def __init__(self,*args):
    super(PrometheusAlertManagerAlerter, self).__init__(*args)
    self.alertmanager_url = self.rule.get('alertmanager_url')

  def alert(self, matches):
    alerts = []
    for match in matches:
      myalert = {}
      myalert['labels'] = {}

      if "kubernetes" in match:
        for key,val in match["kubernetes"].iteritems():
          if key != 'labels':
            key = self.conform_key(key)
            myalert['labels'][key]=val
          else:
            for key2,val2 in match["kubernetes"]["labels"].iteritems():
              key2 = self.conform_key(key2)
              myalert['labels'][key2]=val2

      myalert['labels']['_index'] = match['_index']
      myalert['labels']['timestamp'] = match['@timestamp']
      myalert['labels']['severity'] = self.rule.get('severity')
      myalert['labels']['alertname'] = self.rule.get('name')
      myalert['labels']['team'] = self.rule.get('team')
      myalert['annotations'] = {}
      elastalert_logger.info(match)
      myalert['annotations']['summary'] = self.rule.get('summary')
      myalert['annotations']['description'] = self.rule.get('description')
      myalert['generatorURL'] = "https://" + self.rule.get('es_host') + match['kibana_link']
      timestamp = datetime.strptime(match['@timestamp'], "%Y-%m-%dT%H:%M:%SZ").isoformat('T')
      myalert['startsAt'] = timestamp + "Z" # < stupid hack
      alerts.append(myalert)

    bodydata = simplejson.dumps(alerts, separators=(',', ':'), sort_keys=False)
    headers = {'content-type':'application/json'}

    try:
      response = requests.post(self.alertmanager_url + '/api/v1/alerts', data=bodydata, headers=headers)
      response.raise_for_status()
    except RequestException as e:
      raise EAException("Error posting to alertmanager: %s" % e)
    elastalert_logger.info("Alert sent to AlertManager")

  def conform_key(self, key):
    key = key.replace('-','_')
    return key

  def get_info(self):
    return {'type': 'Prometheus AlertManager Alerter',
        'alertmanager_url': self.rule['alertmanager_url']}