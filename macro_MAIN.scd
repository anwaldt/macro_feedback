

// Name of the jack client
s.options.device               = "MACRO";

s.options.numInputBusChannels  = 16;
s.options.numOutputBusChannels = 16;
s.options.numAudioBusChannels  = 4096;

s.options.memSize = 65536;

s.boot;

s.waitForBoot(
	{
		ServerMeter(s);
		MIDIClient.init(1);

		{

			////////////////////////////////////////////////////////////////////////////////
			////////////////////////////////////////////////////////////////////////////////

			SynthDef(\macro_micro,{

				|
				in_bus   = 0,
				out_bus  = 0,
				main_fb  = 0,
				gain_bus = 0,
				fb_delay = 0.01
				|

				var in   = SoundIn.ar(in_bus);

				var proc = DelayC.ar(in,1,Lag.kr(fb_delay,0.05));

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


			SynthDef(\macro_output, {

				|
				in_bus       = nil,
				feedback_out = nil,
				speaker_out  = nil,
				//
				hp_cutoff    = 5,
				lp_cutoff    = 20000,
				//
				g1 = 0.5,
				g2 = 0.5,
				g3 = 0,
				g4 = 0
				|

				var in = In.ar(in_bus,1);

				in = LPF.ar(HPF.ar(in,hp_cutoff),lp_cutoff);

				// one feedback output
				Out.ar(feedback_out, in);

				// four speaker outputs
				Out.ar(speaker_out+0, g1*in);
				Out.ar(speaker_out+1, g2*in);
				Out.ar(speaker_out+2, g3*in);
				Out.ar(speaker_out+3, g4*in);

			}).send;


			~mod_BUS      = Bus.control(s,4);
			~fb_gain_BUS  = Array.fill(4,{Bus.control(s,4)});
			~mic_BUS      = Bus.audio(s,4);

			s.sync;

			////////////////////////////////////////////////////////////////////////////////
			////////////////////////////////////////////////////////////////////////////////

			// output shifted to work with Scarlett 18i20
			~mics = Array.fill(4, { arg i; Synth( \macro_micro,
				[
					\gain_bus, ~fb_gain_BUS[i],
					\in_bus,   i,
					\out_bus,  ~mic_BUS //2 //+ ((i+1)%4)
				]
			)});

			~outputs = Array.fill(4, { arg i; Synth.tail(s,\macro_output,
				[
					\in_bus,   ~mic_BUS.index+i,
					\feedback_out,  2+i,
					\speaker_out, 8
				]
			)});

			~modulators = Array.fill(4, { arg i; Synth( \macro_modulator,
				[
					\out_bus, ~mod_BUS.index+i
				]
			)});


			s.sync;


			////////////////////////////////////////////////////////////////////////////////
			////////////////////////////////////////////////////////////////////////////////


			~outputs.do({arg e,i;
				postln(1-(i/3));
				e.set(\g1,i/3, \g2,1-(i/3))});

			//~mics.do({arg e,i; e.map(\fb_gain, ~fb_gain_BUS.index+i)});
			~mics.do({arg e,i; e.map(\fb_delay, ~mod_BUS.index+i)});



			////////////////////////////////////////////////////////////////////////////////
			////////////////////////////////////////////////////////////////////////////////


			/*MIDIdef.cc(\post,

				{ arg ... args;

					args.postln;
				}
			);*/

			MIDIdef.cc(\gain0,

				{ arg ... args;


					var val = (1*(args[0] / 127));
					var ctl = args[1];

					val.postln;

					('Gain: '++val.asString).postln;

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

					('MAIN Feedback: '++val.asString).postln;

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


				('Delay: '++ctl.asString++' = '++val.asString).postln;


				}, [18, 26, 48, 56], nil, nil
			);



			MIDIdef.cc(\freq,
				{
					arg ... args;

					var val;
					val = 5*pow((args[0] / 127),2);

					~modulators.do({arg e,i; e.set(\freq,val*(1+(i/4)))});

					('MOD Freq: '++val.asString).postln;

				}, 31, nil, nil
			);



			MIDIdef.cc(\depth,
				{
					arg ... args;

					var val;
					val = pow((args[0] / 127),2);

					~modulators.do({arg e,i; e.set(\depth,val*(1+(i/4)))});

					('MOD Depth: '++val.asString).postln;

				}, 27, nil, nil
			);



			MIDIdef.cc(\lp,
				{ arg ... args;

					var val;
					val = 20000 * pow((args[0] / 127),4) + 2;

					~outputs.do({arg e,i; e.set(\lp_cutoff,val)});

					('LP: '++val.asString).postln;

				}, 57, nil, nil
			);



			MIDIdef.cc(\hp,
				{ arg ... args;

					var val;
					val = 20000 * pow((args[0] / 127),4) + 2;

					~outputs.do({arg e,i; e.set(\hp_cutoff,val)});

					('HP: '++val.asString).postln;

				}, 61, nil, nil
			);



	}.fork;}
)
