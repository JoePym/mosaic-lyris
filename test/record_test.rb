require File.join(File.dirname(__FILE__),'test_helper')

class TestRecord < Test::Unit::TestCase
  RECORDS = [
    { :email => 'one@one.not', :proof => true, :trashed => false, :state => 'active' },
    { :email => 'two@two.not', :proof => true, :trashed => false, :state => 'active' },
    { :email => 'three@three.not', :proof => true, :trashed => false, :state => 'active' },
    { :email => 'four@four.not', :proof => true, :trashed => false, :state => 'active' },
    { :email => 'five@five.not', :trashed => false, :state => 'active' },
    { :email => 'six@six.not', :trashed => true, :state => 'admin', :statedate => Date.new(2006,6,1) },
    { :email => 'seven@seven.not', :trashed => true, :state => 'unsubscribed', :statedate => Date.new(2007,7,1) },
    { :email => 'eight@eight.not', :trashed => true, :state => 'bounced', :statedate => Date.new(2008,8,1) },
    { :email => 'nine@nine.not', :trashed => false, :state => 'active' },
    { :email => 'ten@ten.not', :trashed => false, :state => 'active' }
  ]

  DEMOGRAPHICS = [
    { 1 => 'on', 2 => '01/02/03', 3 => %w(one three), 4 => %w(two four), 5 => 'three', 6 => 'six', 7 => 'value for every demographic', 8 => 'the date value in demographic 2 should be Jan 2, 2003' },
    { 1 => 'on', 2 => '02/22/22', 5 => 'three', 6 => 'six', 7 => 'no value for multiple selection demographics', 8 => 'the date value in demographic 2 should be Feb 22, 1922' },
    { 1 => 'on', 2 => '03/03/33', 3 => %w(one three), 4 => %w(two four), 5 => 'three', 6 => 'six', 7 => 'every attribute enabled', 8 => 'the date value in demographic 2 should be Mar 3, 1933' },
    nil,
    { 7 => 'active' },
    { 7 => 'trashed by administrator' },
    { 7 => 'unsubscribed' },
    { 7 => 'bounced' },
  ]

  def test_add
    record = Mosaic::Lyris::Record.add 'new@email.not', :list_id => 1, :demographics => DEMOGRAPHICS[0]
    assert_instance_of Mosaic::Lyris::Record, record
    assert_equal 'abcdef1967', record.id
    assert_equal 'new@email.not', record.email
    assert_equal nil, record.proof
    assert_equal false, record.trashed
    assert_equal 'active', record.state
    assert_equal nil, record.statedate
    assert_equal DEMOGRAPHICS[0], record.demographics
  end

  def test_add_duplicate
    assert_raise Mosaic::Lyris::Error do
      record = Mosaic::Lyris::Record.add 'duplicate@email.not', :list_id => 1
    end
  end

  def test_bad_query
    assert_raise ArgumentError do
      records = Mosaic::Lyris::Record.query(:bad, :list_id => 1)
    end
  end

  def test_update
    record = Mosaic::Lyris::Record.update 'active@email.not', :list_id => 1, :state => 'unsubscribed'
    assert_instance_of Mosaic::Lyris::Record, record
    assert_equal 'abcdef1111', record.id
    assert_equal 'active@email.not', record.email
    assert_equal true, record.trashed
    assert_equal 'unsubscribed', record.state
  end

  def test_update_email
    record = Mosaic::Lyris::Record.update 'active@email.not', :list_id => 1, :email => 'updated@email.not'
    assert_instance_of Mosaic::Lyris::Record, record
    assert_equal 'abcdef1111', record.id
    assert_equal 'updated@email.not', record.email
  end

  def test_update_not_found
    assert_raise Mosaic::Lyris::Error do
      record = Mosaic::Lyris::Record.update 'missing@email.not', :list_id => 1
    end
  end

  def test_query_all
    records = Mosaic::Lyris::Record.query(:all, :list_id => 1)
    assert_instance_of Array, records
    assert_equal 10, records.size
    records.each_with_index do |r,i|
      assert_instance_of Mosaic::Lyris::Record, r
      assert_equal 'abcdef%04d' % (i+1), r.id
      assert_equal RECORDS[i][:email], r.email
      assert_equal RECORDS[i][:proof], r.proof
      assert_equal RECORDS[i][:trashed], r.trashed
      assert_equal RECORDS[i][:state], r.state
      assert_equal RECORDS[i][:statedate], r.statedate
      assert_equal DEMOGRAPHICS[i], r.demographics
    end
  end

  def test_query_all_empty
    records = Mosaic::Lyris::Record.query(:all, :list_id => 2)
    assert_instance_of Array, records
    assert_equal 0, records.size
  end

  def test_query_all_paginated
    i = 0
    (1..3).each do |page|
      records = Mosaic::Lyris::Record.query(:all, :list_id => 3, :page => page, :per_page => 4)
      assert_instance_of Array, records
      if page < 3
        assert_equal 4, records.size
      else
        assert_equal 2, records.size
      end
      records.each do |r|
        assert_instance_of Mosaic::Lyris::Record, r
        assert_equal 'abcdef%04d' % (i+1), r.id
        assert_equal RECORDS[i][:email], r.email
        assert_equal RECORDS[i][:proof], r.proof
        assert_equal RECORDS[i][:trashed], r.trashed
        assert_equal RECORDS[i][:state], r.state
        assert_equal RECORDS[i][:statedate], r.statedate
        assert_equal DEMOGRAPHICS[i], r.demographics
        i += 1
      end
    end
  end

  def test_query_active_email
    record = Mosaic::Lyris::Record.query('active@email.not', :list_id => 1)
    assert_instance_of Mosaic::Lyris::Record, record
    assert_equal 'abcdef1111', record.id
    assert_equal 'active@email.not', record.email
    assert_equal true, record.proof
    assert_equal false, record.trashed
    assert_equal 'active', record.state
    assert_equal Time.parse("2001-01-11 01:01:01 PST"), record.joindate
    assert_equal nil, record.statedate
    assert_equal({ 2 => '01/11/81', 7 => 'this email is active' }, record.demographics)
  end

  def test_query_admin_trashed_email
    record = Mosaic::Lyris::Record.query('admin.trashed@email.not', :list_id => 1)
    assert_instance_of Mosaic::Lyris::Record, record
    assert_equal 'abcdef2222', record.id
    assert_equal 'admin.trashed@email.not', record.email
    assert_equal nil, record.proof
    assert_equal true, record.trashed
    assert_equal 'admin', record.state
    assert_equal Time.parse("2002-02-12 02:02:02 PST"), record.joindate
    assert_equal Date.new(2009,11,17), record.statedate
    assert_equal({ 2 => '02/12/82', 7 => 'this email is admin trashed' }, record.demographics)
  end

  def test_query_bounced_email
    record = Mosaic::Lyris::Record.query('bounced@email.not', :list_id => 1)
    assert_instance_of Mosaic::Lyris::Record, record
    assert_equal 'abcdef3333', record.id
    assert_equal 'bounced@email.not', record.email
    assert_equal nil, record.proof
    assert_equal true, record.trashed
    assert_equal 'bounced', record.state
    assert_equal Time.parse("2003-03-13 03:03:03 PST"), record.joindate
    assert_equal Date.new(2009,11,17), record.statedate
    assert_equal({ 2 => '03/13/93', 7 => 'this email is bounced' }, record.demographics)
  end

  def test_query_unsubscribed_email
    record = Mosaic::Lyris::Record.query('unsubscribed@email.not', :list_id => 1)
    assert_instance_of Mosaic::Lyris::Record, record
    assert_equal 'abcdef4444', record.id
    assert_equal 'unsubscribed@email.not', record.email
    assert_equal nil, record.proof
    assert_equal true, record.trashed
    assert_equal 'unsubscribed', record.state
    assert_equal Time.parse("2004-04-14 04:04:04 PDT"), record.joindate
    assert_equal Date.new(2009,11,17), record.statedate
    assert_equal({ 2 => '04/14/94', 7 => 'this email is unsubscribed' }, record.demographics)
  end

  def test_query_email_not_found
    assert_raise Mosaic::Lyris::Error do
      record = Mosaic::Lyris::Record.query('missing@email.not', :list_id => 1)
    end
  end
end
