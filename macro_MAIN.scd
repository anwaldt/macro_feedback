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
	main_fb  = 0,
	gain_bus = 0,
	fb_delay = 0.01
	|

	var in   = SoundIn.ar(in_bus);

	var proc = DelayC.ar(in,1,fb_delay);

	var g0,g1,g2,g3;

	Out.ar(out_bus+0, main_fb* In.kr(gain_bus + 0,1) * proc);
	Out.ar(out_bus+1, main_fb* In.kr(gain_bus + 1,1) * proc);
	Out.ar(out_bus+2, main_fb* In.kr(gain_bus + 2,1) * proc);
	Out.ar(out_bus+3, main_fb* In.kr(gain_bus + 3,1) * proc);

}).send;


SynthDef(\macro_modulator, {

	|
	freq  = 1,
	mean  = 0.1,
	depth = 0.01,
	//
	out_bus = nil
	|

	var mod = mean+(depth* (1 + SinOsc.kr(freq)) * 0.5);

	Out.kr(out_bus, mod);

}).send;


~mod_BUS      = Bus.control(s,4);
~fb_gain_BUS  = Array.fill(4,{Bus.control(s,4)});


)


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

~fb_gain_BUS[0].scope

~lfo_BUS.scope;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

(

// ~lfo = { arg freq = 1, mean = 0.1, depth=0.01;
//
// 	var mod = mean+(depth* (1+SinOsc.kr(freq)) * 0.5);
//
// 	Out.kr(~lfo_BUS.index,mod);
//
// }.play;
//

// output shifted to work with Scarlett 18i20
~mics = Array.fill(4, { arg i; Synth( \macro_micro,
	[
		\gain_bus, ~fb_gain_BUS[i],
		\in_bus,   i,
		\out_bus,  2 //+ ((i+1)%4)
	]
)});


~modulators = Array.fill(4, { arg i; Synth( \macro_modulator,
	[
		\out_bus, ~mod_BUS.index+i
	]
)});


)


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

(

//~mics.do({arg e,i; e.map(\fb_gain, ~fb_gain_BUS.index+i)});
~mics.do({arg e,i; e.map(\fb_delay, ~mod_BUS.index+i)});

)


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

(

MIDIdef.cc(\post,

	{ arg ... args;

		args.postln;
	}
);

MIDIdef.cc(\gain0,

	{ arg ... args;


		var val = (1*(args[0] / 127));
		var ctl = args[1];

		val.postln;

		switch(ctl,
			16, {~fb_gain_BUS[0].setAt(0,val)},
			17, {~fb_gain_BUS[0].setAt(2,val)},
			20, {~fb_gain_BUS[0].setAt(1,val)},
			21, {~fb_gain_BUS[0].setAt(3,val)},
			//
			nil
		);


		switch(ctl,
			24, {~fb_gain_BUS[1].setAt(0,val)},
			25, {~fb_gain_BUS[1].setAt(2,val)},
			28, {~fb_gain_BUS[1].setAt(1,val)},
			29, {~fb_gain_BUS[1].setAt(3,val)},
			//
			nil
		);


		switch(ctl,
			46, {~fb_gain_BUS[2].setAt(0,val)},
			47, {~fb_gain_BUS[2].setAt(2,val)},
			50, {~fb_gain_BUS[2].setAt(1,val)},
			51, {~fb_gain_BUS[2].setAt(3,val)},
			//
			nil
		);

		switch(ctl,
			54, {~fb_gain_BUS[3].setAt(0,val)},
			55, {~fb_gain_BUS[3].setAt(2,val)},
			58, {~fb_gain_BUS[3].setAt(1,val)},
			59, {~fb_gain_BUS[3].setAt(3,val)},
			//
			nil
		);

		//}, nil, nil, nil
	}, [16,17,20,21, 24,25,28,29, 46,47,50,51, 54,55,58,59], nil, nil
);



MIDIdef.cc(\main_fb,
	{
		arg ... args;


		var val;
		val = pow((args[0] / 127),2);

		~mics.do({arg e; e.set(\main_fb,val)});

		// args.postln;
		val.postln;

	}, 62, nil, nil
);



MIDIdef.cc(\delay,
	{
		arg ... args;

		var ctl = args[1];
		var val = pow((args[0] / 127),2);

		switch(ctl,
			18, {~modulators[0].set(\mean,val)},
			26, {~modulators[1].set(\mean,val)},
			48, {~modulators[2].set(\mean,val)},
			56, {~modulators[3].set(\mean,val)}
		);

	}, [18, 26, 48, 56], nil, nil
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


)

~lfo.set(\mean,0.1)
~lfo.set(\depth,0.1)

~fb_gain_BUS.scope
~fb_delay_BUS.scope