defaults {
	notifications disabled;
}
module FrameworkBench {
	value Message {
		String message;
	}
	aggregate World(id) {
		int id;
		int randomNumber;
	}
	aggregate Fortune(id) {
		int id;
		string message;
	}
	report Queries5 {
		int id1;
		int id2;
		int id3;
		int id4;
		int id5;
		World world1 'it => it.id == id1';
		World world2 'it => it.id == id2';
		World world3 'it => it.id == id3';
		World world4 'it => it.id == id4';
		World world5 'it => it.id == id5';
	}
	value Id10 {
		int id1;
		int id2;
		int id3;
		int id4;
		int id5;
		int id6;
		int id7;
		int id8;
		int id9;
		int id10;
	}
	report Queries10 {
		Id10 id;
		World world1 'it => it.id == id.id1';
		World world2 'it => it.id == id.id2';
		World world3 'it => it.id == id.id3';
		World world4 'it => it.id == id.id4';
		World world5 'it => it.id == id.id5';
		World world6 'it => it.id == id.id6';
		World world7 'it => it.id == id.id7';
		World world8 'it => it.id == id.id8';
		World world9 'it => it.id == id.id9';
		World world10 'it => it.id == id.id10';
	}
	value Id15 {
		int id1;
		int id2;
		int id3;
		int id4;
		int id5;
		int id6;
		int id7;
		int id8;
		int id9;
		int id10;
		int id11;
		int id12;
		int id13;
		int id14;
		int id15;
	}
	report Queries15 {
		Id15 id;
		World world1 'it => it.id == id.id1';
		World world2 'it => it.id == id.id2';
		World world3 'it => it.id == id.id3';
		World world4 'it => it.id == id.id4';
		World world5 'it => it.id == id.id5';
		World world6 'it => it.id == id.id6';
		World world7 'it => it.id == id.id7';
		World world8 'it => it.id == id.id8';
		World world9 'it => it.id == id.id9';
		World world10 'it => it.id == id.id10';
		World world11 'it => it.id == id.id11';
		World world12 'it => it.id == id.id12';
		World world13 'it => it.id == id.id13';
		World world14 'it => it.id == id.id14';
		World world15 'it => it.id == id.id15';
	}
}