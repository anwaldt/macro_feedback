(

// Name of the jack client
s.options.device               = "MACRO";

s.options.numInputBusChannels  = 16;
s.options.numOutputBusChannels = 16;
s.options.numAudioBusChannels  = 4096;

s.options.memSize = 65536;

s.boot;

MIDIClient.init(1);

ServerMeter(s);

)

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
(

// s.boot;
// s.waitForBoot({

SynthDef(\macro_micro,{

	|
	in_bus   = 0,
	out_bus  = 0,
	fb_gain  = 0,
	fb_delay = 0.01
	|

	var in   = SoundIn.ar(in_bus);

	var proc = DelayC.ar(in*fb_gain,1, fb_delay);

	Out.ar(out_bus, proc);

}).send;


~lfo_freq_BUS  = Bus.control(s,1);
~lfo_depth_BUS = Bus.control(s,1);

~lfo_BUS = Bus.control(s,1);

~fb_gain_BUS  = Bus.control(s,4);

//~fb_gain_BUS  = Array.fill(4,Bus.control(s,4));


~fb_delay_BUS = Bus.control(s,4);

~lfo_BUS.scope;

)


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
~lfo.free
~lfo.set(\mean,0.2)
~lfo.set(\depth,0.1)


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

(

~lfo = { arg freq = 1, mean = 0.1, depth=0.01;

	var mod = mean+(depth* (1+SinOsc.kr(freq)) * 0.5);

	Out.kr(~lfo_BUS.index,mod);

}.play;


// output shifted to work with Scarlett 18i20
~mics = Array.fill(4, { arg i; Synth( \macro_micro,
	[
		\in_bus,  i,
		\out_bus, 2 + ((i+1)%4)
	]
)});


)


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

(

~mics.do({arg e,i; e.map(\fb_gain, ~fb_gain_BUS.index+i)});
~mics.do({arg e,i; e.map(\fb_delay, ~lfo_BUS.index)});

)


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

(

MIDIdef.cc(\gain0,

	{
		arg ... args;

		var val;
		val = (1*(args[0] / 127));
		args.postln;

		~fb_gain_BUS.setAt(0,val);
	}, 16, nil, nil
);

MIDIdef.cc(\gain1,
	{
		arg ... args;

		var val;
		val = (1*(args[0] / 127));
		args.postln;

		~fb_gain_BUS.setAt(1,val);
	}, 20, nil, nil
);

MIDIdef.cc(\gain2,
	{
		arg ... args;

		var val;
		val = (1*(args[0] / 127));
		args.postln;

		~fb_gain_BUS.setAt(2,val);
	}, 24, nil, nil
);

MIDIdef.cc(\gain3,
	{
		arg ... args;

		var val;
		val = (1*(args[0] / 127));
		args.postln;

		~fb_gain_BUS.setAt(3,val);
	}, 28, nil, nil
);






MIDIdef.cc(\delay,
	{
		arg ... args;

		var val;
		val = pow((args[0] / 127),2);

		~lfo.set(\mean,val);

		val.postln;
		// ~fb_delay_BUS.setAll(val);

	}, 23, nil, nil
);

MIDIdef.cc(\depth,
	{
		arg ... args;

		var val;
		val = pow((args[0] / 127),2);

		~lfo.set(\depth,val);

		val.postln;
		// ~fb_delay_BUS.setAll(val);

	}, 27, nil, nil
);


MIDIdef.cc(\freq,
	{
		arg ... args;

		var val;
		val = 5*pow((args[0] / 127),2);

		~lfo.set(\freq,val);

		val.postln;
		// ~fb_delay_BUS.setAll(val);

	}, 31, nil, nil
);



)

~lfo.set(\mean,0.1)
~lfo.set(\depth,0.1)

~fb_gain_BUS.scope
~fb_delay_BUS.scope