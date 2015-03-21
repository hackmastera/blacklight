require 'spec_helper'

describe Blacklight::SolrResponse::Facets do
  describe Blacklight::SolrResponse::Facets::FacetField do

    describe "A field with default options" do
      subject { Blacklight::SolrResponse::Facets::FacetField.new "my_field", [] }

      its(:name) { should eq "my_field" }
      its(:limit) { should eq 100 }
      its(:sort) { should eq 'count' }
      its(:offset) { should eq 0 }
    end

    describe "A field with additional options" do
      subject { Blacklight::SolrResponse::Facets::FacetField.new "my_field", [], limit: 15, sort: 'alpha', offset: 23 }

      its(:name) { should eq "my_field" }
      its(:limit) { should eq 15 }
      its(:sort) { should eq 'alpha' }
      its(:offset) { should eq 23 }
    end
  end

  describe "#facet_by_field_name" do
    let(:facet_field) { ['my_field', []] }
    let(:response_header) { { params: request_params }}
    let(:request_params) { Hash.new }
    subject { Blacklight::SolrResponse.new({responseHeader: response_header, facet_counts: { facet_fields: [facet_field] }}.with_indifferent_access, request_params)  }

    describe "#limit" do
      it "should extract a field-specific limit value" do
        request_params['f.my_field.facet.limit'] = "10"
        request_params['facet.limit'] = "15"
        expect(subject.facet_by_field_name('my_field').limit).to eq 10
      end

      it "should extract a global limit value" do
        request_params['facet.limit'] = "15"
        expect(subject.facet_by_field_name('my_field').limit).to eq 15
      end

      it "should be the solr default limit if no value is found" do
        expect(subject.facet_by_field_name('my_field').limit).to eq 100
      end
    end

    describe "#offset" do
      it "should extract a field-specific offset value" do
        request_params['f.my_field.facet.offset'] = "10"
        request_params['facet.offset'] = "15"
        expect(subject.facet_by_field_name('my_field').offset).to eq 10
      end

      it "should extract a global offset value" do
        request_params['facet.offset'] = "15"
        expect(subject.facet_by_field_name('my_field').offset).to eq 15
      end

      it "should be nil if no value is found" do
        expect(subject.facet_by_field_name('my_field').offset).to eq 0
      end
    end

    describe "#sort" do
      it "should extract a field-specific sort value" do
        request_params['f.my_field.facet.sort'] = "alpha"
        request_params['facet.sort'] = "index"
        expect(subject.facet_by_field_name('my_field').sort).to eq 'alpha'
      end

      it "should extract a global sort value" do
        request_params['facet.sort'] = "alpha"
        expect(subject.facet_by_field_name('my_field').sort).to eq 'alpha'
      end

      it "should default to count if no value is found and the default limit is used" do
        expect(subject.facet_by_field_name('my_field').sort).to eq 'count'
      end
      
      it "should default to index if no value is found and the limit is unlimited" do
        request_params['facet.limit'] = -1
        expect(subject.facet_by_field_name('my_field').sort).to eq 'index'
      end
    end
  end

  context "facet.missing" do
    let(:response) do
      {
        facet_counts: {
          facet_fields: {
            some_field: ['a', 1, nil, 2]
          }
        }
      }
    end
    
    subject { Blacklight::SolrResponse.new(response, {}) }

    it "should mark the facet.missing field with a human-readable label and fq" do
      missing = subject.aggregations["some_field"].items.select { |i| i.value.nil? }.first

      expect(missing.label).to eq "[Missing]"
      expect(missing.fq).to eq "-some_field:[* TO *]"
    end
  end

  describe "query facets" do
    let(:facet_config) { 
      double(
        key: 'my_query_facet_field',
        :query => {
           'a_simple_query' => { :fq => 'field:search', :label => 'A Human Readable label'},
           'another_query' => { :fq => 'field:different_search', :label => 'Label'},
           'without_results' => { :fq => 'field:without_results', :label => 'No results for this facet'}
           }
      )
    }

    let(:blacklight_config) { double(facet_fields: { 'my_query_facet_field' => facet_config } )}

    let(:response) do
      { 
        facet_counts: {
          facet_queries: {
            'field:search' => 10,
            'field:different_search' => 2,
            'field:not_appearing_in_the_config' => 50,
            'field:without_results' => 0
          }
        }
      }
    end

    subject { Blacklight::SolrResponse.new(response, {}, blacklight_config: blacklight_config) }

    it"should convert the query facets into a double RSolr FacetField" do
      field = subject.aggregations['my_query_facet_field']

      expect(field).to be_a_kind_of Blacklight::SolrResponse::Facets::FacetField

      expect(field.name).to eq'my_query_facet_field'
      expect(field.items.size).to eq 2
      expect(field.items.map { |x| x.value }).to_not include 'field:not_appearing_in_the_config'

      facet_item = field.items.select { |x| x.value == 'a_simple_query' }.first

      expect(facet_item.value).to eq 'a_simple_query'
      expect(facet_item.hits).to eq 10
      expect(facet_item.label).to eq 'A Human Readable label'
    end
  end

  describe "pivot facets" do
    let(:facet_config) {
      double(key: 'my_pivot_facet_field', query: nil, pivot: ['field_a', 'field_b'])
    }
    
    let(:blacklight_config) { double(facet_fields: { 'my_pivot_facet_field' => facet_config } )}

    let(:response) do
      { 
        facet_counts: {
          facet_pivot: { 
            'field_a,field_b' => [
              {
                field: 'field_a', 
                value: 'a', 
                count: 10, 
                pivot: [{field: 'field_b', value: 'b', count: 2}]
              }]
          }
        }
      }
    end

    subject { Blacklight::SolrResponse.new(response, {}, blacklight_config: blacklight_config) }

    it "should convert the pivot facet into a double RSolr FacetField" do
      field = subject.aggregations['my_pivot_facet_field']

      expect(field).to be_a_kind_of Blacklight::SolrResponse::Facets::FacetField

      expect(field.name).to eq 'my_pivot_facet_field'

      expect(field.items.size).to eq 1

      expect(field.items.first).to respond_to(:items)

      expect(field.items.first.items.size).to eq 1
      expect(field.items.first.items.first.fq).to eq({ 'field_a' => 'a' })
    end
  end

end
