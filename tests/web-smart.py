#!/usr/bin/env python3
"""Check ATA/NVMe SMART normalization without hardware access."""
import importlib.util
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
from unittest.mock import patch

root = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('hdd_web_server', root / 'web/server.py')
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)

ata = {'model_name': 'Test HDD', 'serial_number': 'ABC', 'smart_status': {'passed': True},
       'temperature': {'current': 39}, 'power_on_time': {'hours': 120},
       'form_factor': {'name': '2.5 inches'},
       'sata_version': {'string': 'SATA 3.3'},
       'interface_speed': {'current': {'string': '6.0 Gb/s'}, 'max': {'string': '6.0 Gb/s'}},
       'ata_smart_attributes': {'table': [{'id': 5, 'name': 'Reallocated_Sector_Ct', 'value': 100, 'thresh': 36, 'raw': {'string': '0'}}]}}
with patch.object(app.subprocess, 'run', return_value=SimpleNamespace(stdout=json.dumps(ata), stderr='', returncode=0)) as run:
    result = app.smart_details({'name': 'sda', 'rotation': '1', 'model': 'Test HDD'})
    assert run.call_args.args[0] == ['smartctl', '-j', '-a', '-n', 'standby', '/dev/sda']
    assert result['passed'] is True and result['attributes'][0]['normalized'] == 100
    assert result['formFactor'] == '2.5 inches'
    assert result['link']['sataVersion'] == 'SATA 3.3' and result['link']['speed'] == '6.0 Gb/s'

nvme = {'nvme_smart_health_information_log': {'critical_warning': 0, 'available_spare': 99, 'percentage_used': 7},
        'temperature': {'current': 40}, 'power_on_time': {'hours': 50}}
with patch.object(app.subprocess, 'run', return_value=SimpleNamespace(stdout=json.dumps(nvme), stderr='', returncode=0)) as run:
    result = app.smart_details({'name': 'nvme0n1', 'rotation': '0', 'model': 'Test SSD'})
    assert run.call_args.args[0] == ['smartctl', '-j', '-a', '/dev/nvme0n1']
    assert result['passed'] is True and result['temperature'] == 40
    assert any(item['key'] == 'percentage_used' for item in result['attributes'])

assert app.smart_written_bytes({'nvme_smart_health_information_log': {'data_units_written': 1000}}) == (512000000, 'nvme')
assert app.smart_written_bytes({'ata_device_statistics': {'pages': [{'table': [{'name': 'Logical Sectors Written', 'value': 4096}]}]}, 'logical_block_size': 4096}) == (16777216, 'ata-statistics')
assert app.smart_written_bytes({'ata_smart_attributes': {'table': [{'id': 241, 'raw': {'value': 1000000}}]}}) == (None, '')
rows = [{'name': 'sda', 'type': 'disk', 'children': [{'name': 'sda1', 'fsused': '1000', 'uuid': 'A', 'mountpoints': ['/data']}]},
        {'name': 'sdb', 'type': 'disk', 'children': [{'name': 'sdb1', 'fsused': '1000', 'uuid': 'A', 'mountpoints': ['/data']},
                                                 {'name': 'sdb2', 'fsused': '500', 'uuid': 'B', 'mountpoints': [None]}]}]
with patch.object(app.subprocess, 'run', return_value=SimpleNamespace(stdout=json.dumps({'blockdevices': rows}), returncode=0)):
    assert app.storage_usage({'sda', 'sdb'}, {'sda': {'size': 2000}, 'sdb': {'size': 3000}}) == {'totalBytes': 5000, 'usedBytes': 1000}

zpool_status = '  pool: tank\n  /dev/sda1 ONLINE\n  /dev/sdb1 ONLINE\n  pool: foreign\n  /dev/sdz1 ONLINE\n'
zpool_list = 'tank\t2000\nforeign\t3000\n'
with patch.object(app.shutil, 'which', return_value='/usr/sbin/zpool'), patch.object(app.subprocess, 'run', side_effect=[SimpleNamespace(returncode=0, stdout=zpool_status), SimpleNamespace(returncode=0, stdout=zpool_list)]):
    assert app.zpool_allocated({'sda', 'sdb'}) == 2000

zfs_rows = [{'name': 'sda', 'type': 'disk', 'children': [{'name': 'sda1', 'fstype': 'zfs_member', 'mountpoints': [None]}]}]
with patch.object(app.subprocess, 'run', return_value=SimpleNamespace(stdout=json.dumps({'blockdevices': zfs_rows}), returncode=0)) as run, patch.object(app, 'zpool_allocated', return_value=2500) as pools:
    assert app.storage_usage({'sda'}, {'sda': {'size': 5000}}) == {'totalBytes': 5000, 'usedBytes': 2500}
    assert 'FSTYPE' in run.call_args.args[0][4]
    pools.assert_called_once()

assert app.smart_temperature({'temperature': {'current': 42}}) == 42
assert app.smart_temperature({'nvme_smart_health_information_log': {'temperature': 47}}) == 47
assert app.smart_temperature({'ata_smart_attributes': {'table': [{'id': 194, 'raw': {'value': 35}}]}}) == 35
assert app.smart_temperature({'temperature': {'current': 500}}) is None
assert app.nvme_temperature_thresholds({'nvme_composite_temperature_threshold': {'warning': 70, 'critical': 82}}) == {'temperatureWarning': 70, 'temperatureCritical': 82}
with patch.object(app.subprocess, 'run', return_value=SimpleNamespace(stdout=json.dumps({'temperature': {'current': 52}, 'nvme_composite_temperature_threshold': {'warning': 70, 'critical': 82}}), stderr='', returncode=0)) as run:
    app.probe_temperature('nvme0n1', 'nvme')
    assert run.call_args.args[0] == ['smartctl', '-j', '-i', '-A', '/dev/nvme0n1']
    assert app.cached_temperature('nvme0n1', 'nvme') == (52, {'temperatureWarning': 70, 'temperatureCritical': 82}, 'available')
with patch.object(app.subprocess, 'run', return_value=SimpleNamespace(stdout=json.dumps({'temperature': {'current': 38}}), stderr='', returncode=0)) as run:
    app.probe_temperature('sda', 'sata')
    assert run.call_args.args[0] == ['smartctl', '-j', '-A', '-n', 'standby', '/dev/sda']
    assert app.cached_temperature('sda', 'sata')[0] == 38

with patch.object(app, 'snapshot', return_value={'disks': [{'name': 'sda'}]}) as scan:
    assert app.web_snapshot()['disks'][0]['name'] == 'sda'
    assert app.web_snapshot()['disks'][0]['name'] == 'sda'
    assert scan.call_count == 1

with patch.object(app.subprocess, 'run', return_value=SimpleNamespace(stdout='not JSON', stderr='standby', returncode=2)):
    result = app.smart_details({'name': 'sdb', 'rotation': '1', 'model': ''})
    assert result['available'] is False and result['error'] == 'standby' and result['temperatureState'] == 'unavailable'

sleeping = {'smartctl': {'messages': [{'string': 'Device is in STANDBY mode, exit(2)'}]}}
with patch.object(app.subprocess, 'run', return_value=SimpleNamespace(stdout=json.dumps(sleeping), stderr='', returncode=2)):
    app.probe_temperature('sdb', 'sata')
    assert app.cached_temperature('sdb', 'sata')[2] == 'sleeping'
    assert app.smart_details({'name': 'sdb', 'rotation': '1', 'model': ''})['temperatureState'] == 'sleeping'
assert app.smart_standby({'smartctl': {'messages': [{'string': 'Device failed to open'}]}}, 2) is False

with tempfile.TemporaryDirectory() as directory:
    base = Path(directory)
    with patch.object(app, 'STATE', base), patch.object(app, 'PREFERENCES', base / 'web-preferences.json'):
        assert app.preferences()['wakeSleepingOnVisit'] is False
        app.save_preferences(True)
        assert app.preferences()['wakeSleepingOnVisit'] is True
        assert (base / 'web-preferences.json').stat().st_mode & 0o777 == 0o600
        calls = []
        def fake_run(args, **_kwargs):
            calls.append(args)
            raw = sleeping if len(calls) == 1 else {'temperature': {'current': 43}}
            return SimpleNamespace(stdout=json.dumps(raw), stderr='', returncode=2 if len(calls) == 1 else 0)
        with patch.object(app, 'lsblk_details', return_value={'sdb': {'rota': 1, 'tran': 'sata'}, 'nvme0n1': {'rota': 0, 'tran': 'nvme'}}), patch.object(app.subprocess, 'run', side_effect=fake_run):
            app.wake_sleeping_drives()
        assert [item[-1] for item in calls] == ['/dev/sdb'] * 3
        assert any('-n' not in item for item in calls)
        assert app.cached_temperature('sdb', 'sata')[0] == 43

with tempfile.TemporaryDirectory() as directory:
    base = Path(directory)
    block = base / 'block'
    links = base / 'ata_link'
    disk = base / 'devices/ata2/host2/target2:0:0/2:0:0:0'
    disk.mkdir(parents=True)
    (block / 'sda').mkdir(parents=True)
    (block / 'sda/device').symlink_to(disk, target_is_directory=True)
    (links / 'link2').mkdir(parents=True)
    (links / 'link2/sata_spd').write_text('6.0 Gbps\n')
    (links / 'link2/hw_sata_spd_limit').write_text('6.0 Gbps\n')
    pci = base / 'devices/pci0000:00/0000:01:00.0'
    namespace = pci / 'nvme/nvme0/nvme0n1'
    namespace.mkdir(parents=True)
    (pci / 'current_link_speed').write_text('16.0 GT/s PCIe\n')
    (pci / 'current_link_width').write_text('4\n')
    (pci / 'max_link_speed').write_text('32.0 GT/s PCIe\n')
    (pci / 'max_link_width').write_text('4\n')
    (block / 'nvme0n1').mkdir(parents=True)
    (block / 'nvme0n1/device').symlink_to(namespace, target_is_directory=True)
    with patch.object(app, 'SYS_BLOCK', block), patch.object(app, 'SYS_ATA_LINK', links):
        assert app.interface_link('sda', 'sata')['speed'] == '6.0 Gbps'
        link = app.interface_link('nvme0n1', 'nvme')
        assert link['version'] == '4.0' and link['width'] == '4'
        assert link['maxVersion'] == '5.0' and link['maxSpeed'] == '32.0 GT/s PCIe'
        assert app.interface_link('../sda', 'sata') == {}

print('web-smart: passed')
