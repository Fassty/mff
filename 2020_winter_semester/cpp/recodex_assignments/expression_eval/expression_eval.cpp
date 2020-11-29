#include <string>
#include <fstream>
#include <iostream>
#include <vector>
#include <memory>
#include <climits>
#include <utility>

using t_arg = std::vector<std::string>;

class AbstractNode {
public:
  virtual ~AbstractNode() {}
	virtual void print(std::ostream& o) const = 0;
  virtual std::int_least32_t evaluate(const std::int_least32_t x) const = 0;
};

using NodePtr = std::unique_ptr< AbstractNode>;

class Expression {
public:
	explicit Expression(NodePtr n)
		: root_(std::move(n)) {}
	friend std::ostream& operator<<(std::ostream& o, const Expression& e);
  std::int_least32_t evaluate(const std::int_least32_t x) const
  {
    return root_->evaluate(x);
  }
private:
	NodePtr root_;
	void print(std::ostream& o) const
	{
		root_->print(o);
	}
};

std::ostream& operator<<(std::ostream& o, const Expression& e)
{
	e.print(o);
	return o;
}



class VarNode : public AbstractNode {
public:
	explicit VarNode(std::string n)
		: name_(std::move(n)) {}
  virtual std::int_least32_t evaluate(const std::int_least32_t x) const override
  {
    return x;
  }
private:
	std::string name_;
	virtual void print(std::ostream& o) const override
	{
		o << name_;
	}
};

class ConstNode : public AbstractNode {
public:
	explicit ConstNode(int n)
		: value_(std::move(n)) {}
  virtual std::int_least32_t evaluate(const std::int_least32_t x) const override
  {
    return value_;
  }
private:
	int value_;
	virtual void print(std::ostream& o) const
	{
		o << value_;
	}
};

class BinNode : public AbstractNode {
public:
	BinNode(NodePtr l, NodePtr r)
		: left_(std::move(l)), right_(std::move(r)) {}
private:
	NodePtr left_, right_;
	virtual void print(std::ostream& o) const
	{
		o << '(';
		left_->print(o);
		o << op();
		right_->print(o);
		o << ')';
	}
  virtual std::int_least32_t evaluate(const std::int_least32_t x) const {
    return func(left_->evaluate(x), right_->evaluate(x));
  }
  virtual std::int_least32_t func(std::int_least32_t l, std::int_least32_t r) const = 0;
	virtual std::string op() const = 0;
};

class AddNode : public BinNode {
public:
	AddNode(NodePtr l, NodePtr r)
		: BinNode(std::move(l), std::move(r)) {}
private:
  virtual std::int_least32_t func(std::int_least32_t l, std::int_least32_t r) const override {
    return l + r;
  }
	virtual std::string op() const { return "+"; }
};

class SubtractNode : public BinNode {
public:
	SubtractNode(NodePtr l, NodePtr r)
		: BinNode(std::move(l), std::move(r)) { }
private:
	NodePtr left_, right_;
  virtual std::int_least32_t func(std::int_least32_t l, std::int_least32_t r) const override {
    return l - r;
  }
	virtual std::string op() const { return "-"; }
};

class MultiplyNode : public BinNode {
public:
	MultiplyNode(NodePtr l, NodePtr r)
		: BinNode(std::move(l), std::move(r)) { }
private:
	NodePtr left_, right_;
  virtual std::int_least32_t func(std::int_least32_t l, std::int_least32_t r) const override {
    return l * r;
  }
	virtual std::string op() const { return "*"; }
};

class DivideNode : public BinNode {
public:
	DivideNode(NodePtr l, NodePtr r)
		: BinNode(std::move(l), std::move(r)) { }
private:
  virtual std::int_least32_t func(std::int_least32_t l, std::int_least32_t r) const override {
    return l / r;
  }
	virtual std::string op() const { return "/"; }
};

class lexer {
public:
	lexer(std::istream& is)
		: is_(is), ch_(0), eof_(false)
	{
		skip();
	}
	char next() const { return ch_; }
  bool eof() const { return eof_; }
	void skip()
	{
		skip1();
		skipws();
	}
	void skipws()
	{
		while (std::isspace(next()))
			skip1();
	}
	void skip1()
	{
		if (!is_.get(ch_))
		{
			eof_ = true;
			ch_ = 0;
		}
	}
private:
	std::istream& is_;
	char ch_;
	bool eof_;
};


NodePtr E(lexer& lex) {
  std::vector<NodePtr> stack;

  while (!lex.eof()) {
    lex.skipws();

    if (std::isdigit(lex.next())) {
      int v = 0;

      do {
        v = 10 * v + (lex.next() - '0');
        lex.skip1();
      } while (std::isdigit(lex.next()));

      lex.skipws();
      stack.push_back(std::make_unique< ConstNode>(v));

    } else if (std::isalpha(lex.next())) {
      std::string s;

      do {
        s.push_back(lex.next());
        lex.skip1();
      } while (std::isalpha(lex.next()));

      lex.skipws();
      stack.push_back(std::make_unique< VarNode>(std::move(s)));

    } else if (lex.next() == '+') {
      NodePtr r = std::move(stack.back());
      stack.pop_back();
      NodePtr l = std::move(stack.back());
      stack.pop_back();

      stack.push_back(std::make_unique< AddNode>(std::move(l), std::move(r)));

      lex.skip();

    } else if (lex.next() == '-') {
      NodePtr r = std::move(stack.back());
      stack.pop_back();
      NodePtr l = std::move(stack.back());
      stack.pop_back();

      stack.push_back(std::make_unique< SubtractNode>(std::move(l), std::move(r)));

      lex.skip();

    } else if (lex.next() == '*') {
      NodePtr r = std::move(stack.back());
      stack.pop_back();
      NodePtr l = std::move(stack.back());
      stack.pop_back();

      stack.push_back(std::make_unique< MultiplyNode>(std::move(l), std::move(r)));

      lex.skip();

    } else if (lex.next() == '/') {
      NodePtr r = std::move(stack.back());
      stack.pop_back();
      NodePtr l = std::move(stack.back());
      stack.pop_back();

      stack.push_back(std::make_unique< DivideNode>(std::move(l), std::move(r)));

      lex.skip();

    } else {
      throw std::runtime_error("Unexpected character");
    }

  }

  if (stack.size() != 1)
      throw std::runtime_error("Invalid expression");

  NodePtr root_ = std::move(stack.back());
  stack.pop_back();

  return root_;
}

Expression parse_expression_tree_from_file(const std::string& fn) {
  std::ifstream fis(fn);
  if (!fis)
    throw std::runtime_error("Cannot open file");

  lexer lex(fis);
  return Expression{ E(lex) };
}

std::pair<int, int> find_min_max_of_expression(const Expression& expr, int imin, int imax) {
    int min = INT_MAX, max = INT_MIN;

    for (auto i = imin; i <= imax; ++i) {
      auto result = expr.evaluate(i);

      if (result < min)
        min = result;

      if (result > max)
        max = result;
    }

    return std::make_pair(min, max);
}

int main(int argc, char** argv)
{
	try {
    // Just to be safe
    t_arg parg(argv + 1, argv + argc);

    auto fname = parg[0];
    auto imin = std::stoi(parg[1]);
    auto imax = std::stoi(parg[2]);

    auto expr = parse_expression_tree_from_file(fname);

    auto min_max = find_min_max_of_expression(expr, imin, imax);

    std::cout << "min=" << min_max.first << ' ' << "max=" << min_max.second << std::endl;
	}
	catch (const std::exception& e)
	{
		std::cout << e.what() << std::endl;
	}

	return 0;
}

