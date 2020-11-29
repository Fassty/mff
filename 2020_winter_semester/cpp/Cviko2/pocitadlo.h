class Counter{
	public:
		Counter(istream& s)
			: chars_(0), words_(0), rows_(0), sents_(0), nums_(0), istream(in_) {}
		void count(void);
		void print(void);
	private:
		istream in_;
		int chars_;
		int words_;
		int rows_;
		int sents_;
		int nums_;
};
