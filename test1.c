// テストコード
// 注意 			: テストコードは常にgccでコンパイルできることを確認する gcc -c test.c
// - 変数宣言
// - 代入
// - 関数宣言
// - 関数呼び出し
// // のコメントアウト
// をサポートする
// hoge関数は引数を標準出力する組み込み関数とする
// 文字コードはUTF-8,改行コードはLFのみとする
int number = 10;
int main(int argc, char **argv)
{
	int a;
	{
		{
		}
	}
	// //コメントはコメントアウト
	a = 123;				// 末尾のコメントもプリプロセッサによって削除
	hoge(a);
	return 0;
}

void fff(int fff)
{
	/* comment あ */
	#if 1
	if (a == 222) {
		switch (b == 333)	// fff
		{
		case 1:
		}
	}else {
	}
	#endif
	return;
}
