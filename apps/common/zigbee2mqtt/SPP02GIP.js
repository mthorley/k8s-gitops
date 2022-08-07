const fz = require('zigbee-herdsman-converters/converters/fromZigbee');
const tz = require('zigbee-herdsman-converters/converters/toZigbee');
const exposes = require('zigbee-herdsman-converters/lib/exposes');
const reporting = require('zigbee-herdsman-converters/lib/reporting');
const extend = require('zigbee-herdsman-converters/lib/extend');
const e = exposes.presets;
const ea = exposes.access;

const definition = {
    fingerprint: [{modelID: 'TS011F', manufacturerName: '_TZ3210_7jnk7l3k'}],
    zigbeeModel: ['TS011F'],
    model: 'SPP02GIP',
    vendor: 'Mercator',
    description: 'Mercator Ikuu Double Outdoors Power Point',
    fromZigbee: [fz.on_off, fz.electrical_measurement, fz.metering, fz.ignore_basic_report, fz.tuya_switch_power_outage_memory],
    toZigbee: [tz.on_off],
    exposes: [e.switch().withEndpoint('left'), e.switch().withEndpoint('right'), e.power().withEndpoint('left'), e.current().withEndpoint('left'), e.voltage().withEndpoint('left').withAccess(ea.STATE), e.energy()],
    endpoint: (device) => {
        return {left: 1, right: 2};
    },
    // The configure method below is needed to make the device reports on/off state changes
    // when the device is controlled manually through the button on it.
    meta: {multiEndpoint: true}, 
    configure: async (device, coordinatorEndpoint, logger) => {
        const endpoint1 = device.getEndpoint(1);
        const endpoint2 = device.getEndpoint(2);
        await reporting.bind(endpoint1, coordinatorEndpoint, ['genBasic', 'genOnOff', 'haElectricalMeasurement', 'seMetering']);
        await reporting.bind(endpoint2, coordinatorEndpoint, ['genOnOff']);
        await reporting.onOff(endpoint1);
        await reporting.onOff(endpoint1);
        await reporting.onOff(endpoint1);
        await reporting.rmsVoltage(endpoint1, {change: 5});
        await reporting.rmsCurrent(endpoint1, {change: 50});
        await reporting.activePower(endpoint1, {change: 1});
        await reporting.onOff(endpoint1);
        await reporting.onOff(endpoint2);
        endpoint1.saveClusterAttributeKeyValue('haElectricalMeasurement', {acCurrentDivisor: 1000, acCurrentMultiplier: 1});
        endpoint1.saveClusterAttributeKeyValue('seMetering', {divisor: 100, multiplier: 1});
	device.save();
    },
};

module.exports = definition;